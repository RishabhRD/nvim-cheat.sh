local M = {}
M.__index = M

function M:new_cheat_list(disable_comment, init_text)
  local obj = {}
  setmetatable(obj, self)
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
      self.line = 1
      selectedLine = selectedLine:gsub('/', ' ')
      if init_text ~= '' then
        selectedLine = string.format('%s %s', init_text, selectedLine)
      end
      require'nvim-cheat':new_cheat(disable_comment, selectedLine)
    end)
  end
  local opts = {
    prompt = {
      border = true,
      title = 'Search',
      highlight = 'Normal',
      prompt_highlight = 'Normal',
    },
    list = {
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
  init_text = init_text:gsub(' ', '')
  if init_text == '' then
    cmd = 'curl cht.sh/:list'
  else
    cmd = string.format('curl cht.sh/%s/:list', init_text)
  end
  opts.data = {
    cmd = cmd
  }
  require'popfix':new(opts)
  return obj
end

return M
