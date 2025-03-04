local api, fn = vim.api, vim.fn

local M = {}

local config = {
   disabled_filetypes = {
      "NvimTree",
      "TelescopePrompt",
      "aerial",
      "alpha",
      "checkhealth",
      "dapui-repl",
      "dapui_breakpoints",
      "dapui_console",
      "dapui_scopes",
      "dapui_stacks",
      "dapui_watches",
      "DressingInput",
      "DressingSelect",
      "help",
      "lazy",
      "NeogitStatus",
      "NeogitLogView",
      "mason",
      "neotest-summary",
      "neo-tree",
      "neo-tree-popup",
      "netrw",
      "noice",
      "notify",
      "prompt",
      "qf",
      "oil",
      "undotree",
  }
}

local function should_disable()
   return vim.tbl_contains(config.disabled_filetypes, vim.bo.ft)
      or vim.api.nvim_buf_get_option(0, "buftype") == "terminal"
end

function M.onInsertEnter()
  local curline = api.nvim_win_get_cursor(0)[1]
  vim.b.insert_top = curline
  vim.b.insert_bottom = curline
  vim.b.whitespace_lastline = curline
end

local function atTipOfUndo()
  local tree = fn.undotree()
  return tree.seq_last == tree.seq_cur
end

local function stripWhitespace(top, bottom)
  -- Only do if the buffer is modifiable
  -- and modified and we are at the tip of an undo tree
  if not (vim.bo.modifiable and vim.bo.modified and atTipOfUndo()) then
    return
  end

  if not top then return end

  -- All conditions passed, go ahead and strip
  -- Handle the user deleting lines at the bottom
  local file_bottom = fn.line('$')

  if top > file_bottom then
    -- The user deleted all the lines; there is nothing to do
    return
  end

  vim.b.bottom = math.min(file_bottom, bottom)

  -- Keep the cursor position and these marks:
  local original_cursor = fn.getcurpos()
  local first_changed = fn.getpos("'[")
  local last_changed = fn.getpos("']")

  vim.cmd("silent exe "..top.." ',' "..vim.b.bottom.. " 's/\\v\\s+$//e'")

  fn.setpos("']", last_changed)
  fn.setpos("'[", first_changed)
  fn.setpos('.', original_cursor)
end

function M.onTextChanged()
  -- Text was modified in non-Insert mode.  Use the '[ and '] marks to find
  -- what was edited and remove its whitespace.
  stripWhitespace(fn.line("'["), fn.line("']"))
end

function M.onTextChangedI()
  if should_disable() then
    return
  end

  -- Handle motion this way (rather than checking if
  -- b:insert_bottom < curline) to catch the case where the user presses
  -- Enter, types whitespace, moves up, and presses Enter again.
  local curline = api.nvim_win_get_cursor(0)[1]

  if vim.b.whitespace_lastline then
    if vim.b.whitespace_lastline < curline then
      -- User inserted lines below whitespace_lastline
      vim.b.insert_bottom = vim.b.insert_bottom + (curline - vim.b.whitespace_lastline)
    elseif vim.b.whitespace_lastline > curline then
      -- User inserted lines above whitespace_lastline
      vim.b.insert_top = math.max(1, vim.b.insert_top - (vim.b.whitespace_lastline - curline))
    end
  end

  vim.b.whitespace_lastline = curline
end

function M.onInsertLeave()
  stripWhitespace(vim.b.insert_top, vim.b.insert_bottom)
end

function M.onBufLeave()
  if api.nvim_get_mode().mode == 'i' then
    stripWhitespace(vim.b.insert_top, vim.b.insert_bottom)
  end
end

function M.onBufEnter()
  if api.nvim_get_mode().mode == 'i' then
    M.onInsertEnter()
  end
end

---@deprecated
function M.setup()
  -- moved to plugin/
end

return M
