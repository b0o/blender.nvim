local has_dap, dap = pcall(require, 'dap')
local has_dap_repl_hl, dap_repl_hl = pcall(require, 'nvim-dap-repl-highlights')

local notify = require 'blender.notify'

---@class BlenderDap
---@field session? table
local M = {
  session = nil,
}

M.is_available = function()
  return has_dap
end

---@class BlenderDapAttachArgs
---@field host string
---@field port number
---@field python_exe string
---@field path_mappings List<unknown>
---@field cwd string

---@param args BlenderDapAttachArgs
M.attach = function(args)
  if not M.is_available() then
    return false
  end
  local adapter = {
    host = args.host,
    port = args.port,
  }
  local config = {
    type = 'blender-python',
    repl_lang = 'python',
    filetype = 'python',
    request = 'attach',
    mode = 'remote',
    name = 'Blender Python Debugger',
    cwd = args.cwd,
    pathMappings = args.path_mappings,
  }
  local session = dap.attach(adapter, config)
  if session == nil then
    notify('Failed to attach to debugger', 'ERROR')
    return false
  end
  M.session = session
  notify('Attached to Blender debugger', 'TRACE')
  return true
end

local fallback_repl_buf

---@return number
M.get_fallback_repl_buf = function()
  local buf = fallback_repl_buf
  if not fallback_repl_buf or not vim.api.nvim_buf_is_valid(fallback_repl_buf) then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      M.is_available() and 'No active debug session' or 'Debugging disabled: nvim-dap not installed',
    })
  end
  fallback_repl_buf = buf
  return buf
end

---@return number?
M.get_repl_buf = function()
  if not M.is_available() then
    return nil
  end
  local buf = vim.fn.bufnr 'dap-repl'
  if buf == -1 and M.session and not M.session.closed then
    -- dap-repl-highlights must be set up before opening the repl
    if has_dap_repl_hl then
      dap_repl_hl.setup()
    end
    -- keep track of all windows before opening the repl so we can hide the new one
    -- that nvim-dap opens
    local all_wins = vim.api.nvim_list_wins()
    local open_wins = {}
    for _, win in pairs(all_wins) do
      open_wins[win] = true
    end
    pcall(dap.repl.open)
    buf = vim.fn.bufnr 'dap-repl'
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if not open_wins[win] then
        pcall(vim.api.nvim_win_hide, win)
        break
      end
    end
  end
  if not buf or buf == -1 then
    return nil
  end
  vim.schedule(function()
    vim.api.nvim_buf_call(buf, function()
      -- fix issue where the "dap> " prompt doesn't show up at first
      vim.cmd 'normal! i'
    end)
  end)
  return buf
end

return M
