local M = {}
M.__index = M
local popfix = require'popfix'
local util = require'popfix.util'
local job = require'popfix.job'
local api = vim.api
local floating_win = require'popfix.floating_win'
local mapping = require'popfix.mappings'

local function setBufferType(bufnr, type)
    api.nvim_buf_set_option(bufnr, 'buftype', type)
end

function M:new_cheat(disable_comment, init_text)
    local obj = {}
    setmetatable(obj, self)
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
	obj.window = win_buf.win
	obj.buffer = win_buf.buf
	setBufferType(obj.buffer, 'nofile')
	return win_buf
    end
    local function startFuzzySearch(line)
	local function select_next(popup)
	    popup:select_next()
	end
	local function select_prev(popup)
	    popup:select_prev()
	end
	local function close_cancelled(popup)
	    popup:close()
	end
	local function select_fuzzy_handler(popup)
	    popup:close(function(_, selectedLine)
		selectedLine = selectedLine:gsub('/', ' ')
		if line ~= '' then
		    selectedLine = string.format('%s %s', line, selectedLine)
		end
		M:new_cheat(disable_comment, selectedLine)
	    end)
	end
	local opts = {
	    prompt = {
		border = true,
		title = 'Search',
		highlight = 'Normal',
		prompt_highlight = 'Normal',
		init_text = init_text
	    },
	    list = {
		title = 'Available Symbols',
		highlight = 'Normal',
		prompt_highlight = 'Normal',
		border = true,
	    },
	    callbacks = {
		on_job_complete = function()
		    vim.cmd('echohl MoreMsg')
		    vim.cmd(string.format([[echomsg '%s']],'Loading symbols for list completed!!!'))
		    vim.cmd('echohl None')
		end
	    },
	    mode = 'editor',
	    keymaps = {
		i = {
		    ['<C-c>'] = close_cancelled,
		    ['<C-y>'] = select_fuzzy_handler,
		    ['<CR>'] = select_fuzzy_handler,
		    ['<C-n>'] = select_next,
		    ['<C-p>'] = select_prev,
		    ['<C-j>'] = select_next,
		    ['<C-k>'] = select_prev,
		},
		n = {
		    ['<CR>'] = select_fuzzy_handler,
		    ['q'] = close_cancelled,
		    ['<C-c>'] = close_cancelled,
		    ['<Esc>'] = close_cancelled,
		    ['j'] = select_next,
		    ['k'] = select_prev,
		}
	    },
	}
	local cmd
	line = line:gsub(' ', '')
	if line == '' then
	    cmd = 'curl cht.sh/:list'
	else
	    cmd = string.format('curl cht.sh/%s/:list', line)
	end
	opts.data = {
	    cmd = cmd
	}
	require'popfix':new(opts)
    end
    local function openCheat(line)
	local firstWhiteSpace = string.find(line, '%s')
	if firstWhiteSpace == nil then
	    return false
	end
	local language = string.sub(line, 1, firstWhiteSpace - 1)
	local query = string.sub(line, firstWhiteSpace + 1)
	query = query:gsub("%s","+")
	vim.cmd('setfiletype '..language)
	local cmd = string.format('curl cht.sh/%s/%s?T', language, query)
	if disable_comment then
	    cmd = cmd..'?Q'
	end
	local function addData(_, newLine)
	    vim.schedule(function()
		if obj.buffer then
		    if api.nvim_buf_is_valid(obj.buffer) then
			local lineCount = api.nvim_buf_line_count(obj.buffer)
			api.nvim_buf_set_lines(obj.buffer, lineCount, lineCount,
			false, {newLine})
		    else
			if obj.job then
			    obj.job:shutdown()
			    obj.job = nil
			end
		    end
		end
	    end)
	end
	local command, args = util.getArgs(cmd)
	obj.job = job:new{
	    command = command,
	    args = args,
	    on_stdout = addData,
	    on_exit = function()
		obj.job = nil
		vim.schedule(function()
		    vim.cmd('echohl MoreMsg')
		    vim.cmd(string.format([[echomsg '%s']],'Finished!!!'))
		    vim.cmd('echohl None')
		end)
	    end,
	}
	obj.job:start()
	return true
    end
    local function edit(_, line)
	vim.schedule(function()
	    local win_buf_pair =  createFloatingWindow()
	    api.nvim_set_current_win(win_buf_pair.win)
	    if not openCheat(line) then
		vim.cmd('q')
		startFuzzySearch(line)
	    end
	end)
    end
    local function split(_, line)
	vim.cmd('split new')
	obj.buffer = api.nvim_get_current_buf()
	obj.window = api.nvim_get_current_win()
	setBufferType(obj.buffer, 'nofile')
	if not openCheat(line) then
	    vim.cmd('q')
	    startFuzzySearch(line)
	end
    end
    local function vert_split(_, line)
	vim.cmd('vert new')
	obj.buffer = api.nvim_get_current_buf()
	obj.window = api.nvim_get_current_win()
	setBufferType(obj.buffer, 'nofile')
	if not openCheat(line) then
	    vim.cmd('q')
	    startFuzzySearch(line)
	end
    end
    local function tab(_, line)
	vim.cmd('tab new')
	obj.buffer = api.nvim_get_current_buf()
	obj.window = api.nvim_get_current_win()
	setBufferType(obj.buffer, 'nofile')
	if not openCheat(line) then
	    vim.cmd('q')
	    startFuzzySearch(line)
	end
    end
    local function close_cancelled(popup)
	popup:close()
	vim.cmd('stopinsert')
    end
    local function edit_close(popup)
	popup:close(edit)
	vim.cmd('stopinsert')
    end
    local function tab_close(popup)
	if obj.job then
	    obj.job:shutdown()
	    obj.job = nil
	end
	popup:close(tab)
	vim.cmd('stopinsert')
    end
    local function split_close(popup)
	popup:close(split)
	vim.cmd('stopinsert')
    end
    local function vert_split_close(popup)
	popup:close(vert_split)
	vim.cmd('stopinsert')
    end
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
		['<C-v>'] = vert_split_close,
		['<C-x>'] = split_close,
		['<C-t>'] = tab_close,
		['<C-c>'] = close_cancelled,
		['<C-y>'] = edit_close,
		['<CR>'] = edit_close,
	    },
	    n = {
		['<CR>'] = edit_close,
		['<C-v>'] = vert_split_close,
		['<C-x>'] = split_close,
		['<C-t>'] = tab_close,
		['q'] = close_cancelled,
		['<C-c>'] = close_cancelled,
		['<Esc>'] = close_cancelled,
	    }
	},
    }
    local popup = popfix:new(opts)
    -- This part should not be here! This is a popfix bug. Once solved it would
    -- be removed.
    local keymap = {
	i = {
	    ['<CR>'] = edit_close,
	}
    }
    mapping.add_keymap(popup.prompt.buffer, keymap, popup)
    return obj
end

return M
