local M = {}

---Run a function in the context of a window with a specific size
---Useful when instantiating a terminal with nvim_open_term
---
---Via: https://github.com/stevearc/overseer.nvim/blob/b04b0b105c07b4f02b3073ea3a98d6eca90bf152/lua/overseer/util.lua#L628
---Copyright (c) 2024 Steven Arcangeli
---MIT License
---
---@param bufnr nil|integer
---@param size {width: integer, height: integer}
---@param callback fun()
M.buf_run_in_sized_win = function(bufnr, size, callback)
  if not bufnr or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  local winid = vim.api.nvim_open_win(bufnr, false, {
    relative = 'editor',
    width = size.width,
    height = size.height,
    row = 0,
    col = 0,
    noautocmd = true,
  })
  local winnr = vim.api.nvim_win_get_number(winid)
  vim.cmd.wincmd { count = winnr, args = { 'w' }, mods = { noautocmd = true } }
  callback()
  vim.cmd.close { count = winnr, mods = { noautocmd = true, emsg_silent = true } }
end

---This is a hack so we don't end up in insert mode after starting a task
---
---Via: https://github.com/stevearc/overseer.nvim/blob/b04b0b105c07b4f02b3073ea3a98d6eca90bf152/lua/overseer/util.lua#L684
---Copyright (c) 2024 Steven Arcangeli
---MIT License
---
---@param prev_mode string The vim mode we were in before opening a terminal
M.hack_around_termopen_autocmd = function(prev_mode)
  -- It's common to have autocmds that enter insert mode when opening a terminal
  vim.defer_fn(function()
    local new_mode = vim.api.nvim_get_mode().mode
    if new_mode ~= prev_mode then
      if string.find(new_mode, 'i') == 1 then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, true, true), 'n', false)
        if string.find(prev_mode, 'v') == 1 or string.find(prev_mode, 'V') == 1 then
          vim.cmd.normal { bang = true, args = { 'gv' } }
        end
      end
    end
  end, 10)
end

---Via: https://github.com/stevearc/overseer.nvim/blob/b04b0b105c07b4f02b3073ea3a98d6eca90bf152/lua/overseer/util.lua#L54
---Copyright (c) 2024 Steven Arcangeli
---MIT License
local function term_get_effective_line_count(bufnr)
  local linecount = vim.api.nvim_buf_line_count(bufnr)

  local non_blank_lines = linecount
  for i = linecount, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, true)[1]
    non_blank_lines = i
    if line ~= '' then
      break
    end
  end
  return non_blank_lines
end

local _cursor_moved_autocmd
---Via: https://github.com/stevearc/overseer.nvim/blob/b04b0b105c07b4f02b3073ea3a98d6eca90bf152/lua/overseer/util.lua#L69
---Copyright (c) 2024 Steven Arcangeli
---MIT License
local function create_cursormoved_tail_autocmd()
  if _cursor_moved_autocmd then
    return
  end
  _cursor_moved_autocmd = vim.api.nvim_create_autocmd('CursorMoved', {
    callback = function(args)
      if vim.bo[args.buf].buftype ~= 'terminal' or args.buf ~= vim.api.nvim_get_current_buf() then
        return
      end
      local lnum = vim.api.nvim_win_get_cursor(0)[1]
      local linecount = vim.api.nvim_buf_line_count(0)
      if lnum == linecount then
        -- TODO remove after https://github.com/folke/neodev.nvim/pull/163 lands
        ---@diagnostic disable-next-line: inject-field
        vim.w.overseer_pause_tail_for_buf = nil
      else
        -- TODO remove after https://github.com/folke/neodev.nvim/pull/163 lands
        ---@diagnostic disable-next-line: inject-field
        vim.w.overseer_pause_tail_for_buf = args.buf
      end
    end,
  })
end

---Via: https://github.com/stevearc/overseer.nvim/blob/b04b0b105c07b4f02b3073ea3a98d6eca90bf152/lua/overseer/util.lua#L199
---Copyright (c) 2024 Steven Arcangeli
---MIT License
---@param bufnr integer
---@return integer[]
M.buf_list_wins = function(bufnr)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  local ret = {}
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == bufnr then
      table.insert(ret, winid)
    end
  end
  return ret
end

---Via: https://github.com/stevearc/overseer.nvim/blob/b04b0b105c07b4f02b3073ea3a98d6eca90bf152/lua/overseer/util.lua#L94
---Copyright (c) 2024 Steven Arcangeli
---MIT License
---
---@param bufnr nil|integer
M.terminal_tail_hack = function(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local winids = M.buf_list_wins(bufnr)
  if vim.tbl_isempty(winids) then
    return
  end
  create_cursormoved_tail_autocmd()
  local linecount = vim.api.nvim_buf_line_count(bufnr)

  local non_blank_lines = term_get_effective_line_count(bufnr)

  local overflow = 6
  local editor_height = vim.o.lines
  local current_win = vim.api.nvim_get_current_win()
  for _, winid in ipairs(winids) do
    local scroll_to_line
    if winid ~= current_win and vim.w[winid].overseer_pause_tail_for_buf ~= bufnr then
      local lnum = vim.api.nvim_win_get_cursor(winid)[1]
      local cursor_at_top = lnum < editor_height
      local not_much_output = linecount < editor_height + overflow
      local num_blank = linecount - non_blank_lines
      if num_blank < 4 then
        scroll_to_line = linecount
      elseif cursor_at_top and not_much_output then
        scroll_to_line = non_blank_lines
      end
    end

    if scroll_to_line then
      local last_line = vim.api.nvim_buf_get_lines(bufnr, scroll_to_line - 1, scroll_to_line, true)[1]
      local scrolloff = vim.api.nvim_get_option_value('scrolloff', { scope = 'local', win = winid })
      vim.api.nvim_set_option_value('scrolloff', 0, { scope = 'local', win = winid })
      vim.api.nvim_win_set_cursor(winid, { scroll_to_line, vim.api.nvim_strwidth(last_line) })
      vim.api.nvim_set_option_value('scrolloff', scrolloff, { scope = 'local', win = winid })
    end
  end
end

return M
