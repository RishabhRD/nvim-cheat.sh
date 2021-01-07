local M = {}
M.__index = M
local popfix = require'popfix'
local util = require'popfix.util'
local job = require'popfix.job'
local api = vim.api
local floating_win = require'popfix.floating_win'
local mapping = require'popfix.mappings'
local historyTable = {}
local historySize = 0

local function setBufferType(bufnr, type)
    api.nvim_buf_set_option(bufnr, 'buftype', type)
end

local function putInHistory(str)
    if historyTable[historySize + 1] == '' then
	historyTable[historySize + 1] = nil
    end
    if str == nil or str == '' then return end
    historyTable[historySize + 1] = str
    historySize = historySize + 1
end

local function stopInsert()
    vim.schedule(function()
	vim.cmd('stopinsert')
    end)
end

local function createFloatingWindow()
    local editorWidth = api.nvim_get_option('columns')
    local editorHeight = api.nvim_get_option("lines")
    local opts = {}
    opts.height = math.ceil(editorHeight * 0.8 - 4)
    opts.width = math.ceil(editorWidth * 0.8)
    opts.row = math.ceil((editorHeight - opts.height) /2 - 1)
    opts.col = math.ceil((editorWidth - opts.width) /2)
    opts.border = true
    opts.title = 'Cheat Sheet'
    local win_buf = floating_win.create_win(opts)
    api.nvim_buf_set_option(win_buf.buf, 'bufhidden', 'wipe')
    api.nvim_win_set_option(win_buf.win, 'winhl', 'Normal:Normal')
    api.nvim_win_set_option(win_buf.win, 'number', true)
    api.nvim_set_current_win(win_buf.win)
    return win_buf
end

local function openCheat(self, line, disable_comment)
    line = string.gsub(line, '^%s*(.-)%s*$', '%1')
    if line == '' then
	return
    end
    local firstWhiteSpace = string.find(line, '%s')
    local language, query, cmd
    if firstWhiteSpace ~= nil then
	language = string.sub(line, 1, firstWhiteSpace - 1)
	query = string.sub(line, firstWhiteSpace + 1)
	query = query:gsub("%s","+")
	cmd = string.format('curl cht.sh/%s/%s?T', language, query)
    else
	language = line
	cmd = string.format('curl cht.sh/%s?T', language)
    end
    vim.cmd('setfiletype '..language)
    if disable_comment then
	cmd = cmd..'?Q'
    end
    local function addData(_, newLine)
	vim.schedule(function()
	    if self.buffer then
		if api.nvim_buf_is_valid(self.buffer) then
		    local lineCount = api.nvim_buf_line_count(self.buffer)
		    api.nvim_buf_set_lines(self.buffer, lineCount, lineCount,
		    false, {newLine})
		else
		    if self.job then
			self.job:shutdown()
			self.job = nil
		    end
		end
	    end
	end)
    end
    local command, args = util.getArgs(cmd)
    self.job = job:new{
	command = command,
	args = args,
	on_stdout = addData,
	on_exit = function()
	    self.job = nil
	    vim.schedule(function()
		vim.cmd('echohl MoreMsg')
		vim.cmd(string.format([[echomsg '%s']],'Finished!!!'))
		vim.cmd('echohl None')
	    end)
	end,
    }
    self.job:start()
    return true
end

local function openCheatList(disable_comment, line)
    vim.schedule(function()
	vim.cmd('q')
	require'nvim-cheat.cheatList':new_cheat_list(disable_comment, line)
    end)
end

local function createCloseFunction(func)
    return function(popup)
	popup:close(func)
	vim.cmd('stopinsert')
    end
end

local function getWrapperForVimCmdString(str)
    return function()
	vim.cmd(str)
    end
end

local function setupResultWindow(self, init_text, disable_comment)
    local function initCheatWindow(line, contextWiseWindowFunction)
	putInHistory(line)
	contextWiseWindowFunction()
	self.buffer = api.nvim_get_current_buf()
	self.window = api.nvim_get_current_win()
	setBufferType(self.buffer, 'nofile')
	if not openCheat(self, line, disable_comment) then
	    openCheatList(disable_comment, line)
	end
    end
    local function edit(_, line)
	initCheatWindow(line, createFloatingWindow)
    end
    local function split(_, line)
	initCheatWindow(line, getWrapperForVimCmdString('split new'))
    end
    local function vert_split(_, line)
	initCheatWindow(line, getWrapperForVimCmdString('vert new'))
    end
    local function tab(_, line)
	initCheatWindow(line, getWrapperForVimCmdString('tab new'))
    end
    local function close(_, line)
	putInHistory(line)
    end
    local function next_history(popup)
	if self.currentHistoryIndex > historySize then return end
	self.currentHistoryIndex = self.currentHistoryIndex + 1
	popup:set_prompt_text(historyTable[self.currentHistoryIndex])
    end
    local function prev_history(popup)
	if self.currentHistoryIndex == historySize + 1 then
	    historyTable[historySize + 1] = popup:get_prompt_text()
	end
	if self.currentHistoryIndex == 1 then return end
	self.currentHistoryIndex = self.currentHistoryIndex - 1
	popup:set_prompt_text(historyTable[self.currentHistoryIndex])
    end
    local function next_history_normal(popup)
	next_history(popup)
	stopInsert()
    end
    local function prev_history_normal(popup)
	prev_history(popup)
	stopInsert()
    end
    local vertSplitFunc = createCloseFunction(vert_split)
    local splitFunc = createCloseFunction(split)
    local tabFunc = createCloseFunction(tab)
    local cancelFunc = createCloseFunction(close)
    local floatingFunc = createCloseFunction(edit)
    local opts = {
	prompt = {
	    border = true,
	    title = 'Search',
	    highlight = 'Normal',
	    prompt_highlight = 'Normal',
	    init_text = init_text
	},
	mode = 'editor',
	keymaps = {
	    i = {
		['<C-v>'] = vertSplitFunc,
		['<C-x>'] = splitFunc,
		['<C-t>'] = tabFunc,
		['<C-c>'] = cancelFunc,
		['<C-y>'] = floatingFunc,
		['<C-n>'] = next_history,
		['<C-p>'] = prev_history,
		['<CR>'] = floatingFunc,
	    },
	    n = {
		['<CR>'] = floatingFunc,
		['<C-v>'] = vertSplitFunc,
		['<C-x>'] = splitFunc,
		['<C-t>'] = tabFunc,
		['q'] = cancelFunc,
		['j'] = next_history_normal,
		['k'] = prev_history_normal,
		['<C-c>'] = cancelFunc,
		['<Esc>'] = cancelFunc,
	    }
	},
	callbacks = {
	    close = close,
	}
    }
    local popup = popfix:new(opts)
    -- This part should not be here! This is a popfix bug. Once solved it would
    -- be removed.
    local keymap = {
	i = {
	    ['<CR>'] = floatingFunc,
	}
    }
    mapping.add_keymap(popup.prompt.buffer, keymap, popup)
end

function M:new_cheat(disable_comment, init_text)
    local obj = {}
    obj.currentHistoryIndex = historySize + 1
    setmetatable(obj, self)
    setupResultWindow(obj, init_text, disable_comment)
    return obj
end

return M
