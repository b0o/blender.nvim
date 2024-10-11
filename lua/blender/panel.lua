local M = {}

-- Panel class
local Panel = {}
Panel.__index = Panel

function Panel.new(opts)
  local self = setmetatable({}, Panel)
  self.buf = opts.buf or vim.api.nvim_create_buf(false, true)
  self.height = opts.height or 20
  self.win = nil
  return self
end

function Panel:show()
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    return
  end

  -- Save the current window
  local current_win = vim.api.nvim_get_current_win()

  -- Create a new window at the bottom
  vim.cmd 'botright new'
  self.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(self.win, self.buf)

  -- Set window options
  vim.api.nvim_win_set_height(self.win, self.height)
  vim.wo[self.win].number = false
  vim.wo[self.win].relativenumber = false
  vim.wo[self.win].signcolumn = 'no'

  -- Return to the original window
  vim.api.nvim_set_current_win(current_win)
end

function Panel:hide()
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
    self.win = nil
  end
end

function Panel:toggle()
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    self:hide()
  else
    self:show()
  end
end

function Panel:set_buf(buf)
  self.buf = buf
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_set_buf(self.win, buf)
  end
end

-- Factory function to create a new panel
function M.create_panel(opts)
  return Panel.new(opts)
end

return M
