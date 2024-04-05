local M = {
  ---@type Server?
  server = nil,
}

---@class Server
---@field private addr? string
local Server = {}

function Server.new()
  local self = setmetatable({
    addr = nil,
  }, { __index = Server })
  return self
end

function Server:start()
  if self.addr == nil then
    self.addr = vim.fn.serverstart()
  end
end

function Server:stop()
  if self.addr ~= nil then
    vim.fn.serverstop(self.addr)
    self.addr = nil
  end
end

function Server:get_addr()
  if self.addr == nil then
    self:start()
  end
  return self.addr
end

M.get_server = function()
  if M.server == nil then
    M.server = Server.new()
  end
  return M.server
end

M.handlers = {}

---@class RpcMessage
---@field type 'setup'

---@class RpcSetupParams : RpcMessage
---@field type 'setup'
---@field blender_port number
---@field debugpy_port number
---@field python_exe string
---@field blender_path string
---@field scripts_folder string
---@field addon_path_mappings List<unknown>
---@field task_id number

---@param params RpcSetupParams
M.handlers.setup = function(params)
  vim.validate {
    blender_port = { params.blender_port, 'number' },
    debugpy_port = { params.debugpy_port, 'number' },
    python_exe = { params.python_exe, 'string' },
    blender_path = { params.blender_path, 'string' },
    scripts_folder = { params.scripts_folder, 'string' },
    addon_path_mappings = { params.addon_path_mappings, 'table' },
    task_id = { params.task_id, 'string' },
  }
  require('blender.dap').attach {
    host = '127.0.0.1', -- TODO: Make dynamic
    port = params.debugpy_port,
    python_exe = params.python_exe,
    cwd = params.scripts_folder,
    path_mappings = params.addon_path_mappings,
    task_id = tonumber(params.task_id) or 0,
  }
end

---@param msg RpcMessage
M.handle = function(msg)
  local handler = M.handlers[msg.type]
  if not handler then
    vim.notify('[Blender.nvim] Received unknown RPC message type: "' .. msg.type .. '"', vim.log.levels.ERROR)
    return
  end
  vim.schedule(function()
    handler(msg)
  end)
end

return M
