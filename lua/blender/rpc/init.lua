local util = require 'blender.util'
local manager = require 'blender.manager'
local RpcClient = require 'blender.rpc.client'

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
---@field type 'setup' | 'addonUpdated'

---@class RpcSetupParams : RpcMessage
---@field type 'setup'
---@field blender_port number
---@field debugpy_enabled boolean
---@field debugpy_port number
---@field python_exe string
---@field blender_path string
---@field scripts_folder string
---@field path_mappings List<unknown>
---@field task_id string

---@param params RpcSetupParams
M.handlers.setup = function(params)
  vim.validate {
    blender_port = { params.blender_port, 'number' },
    debugpy_enabled = { params.debugpy_enabled, 'boolean' },
    debugpy_port = { params.debugpy_port, 'number' },
    python_exe = { params.python_exe, 'string' },
    blender_path = { params.blender_path, 'string' },
    scripts_folder = { params.scripts_folder, 'string' },
    path_mappings = { params.path_mappings, 'table' },
    task_id = { params.task_id, 'string' },
  }
  local task_id = tonumber(params.task_id) or 0
  local rpc_client = RpcClient.new {
    blender_port = params.blender_port,
    debugpy_enabled = params.debugpy_enabled,
    debugpy_port = params.debugpy_port,
    python_exe = params.python_exe,
    blender_path = params.blender_path,
    scripts_folder = params.scripts_folder,
    path_mappings = params.path_mappings,
  }
  manager.attach(task_id, rpc_client)
end

---@class RpcAddonUpdatedParams : RpcMessage
---@field type 'addonUpdated'

---@param params RpcAddonUpdatedParams
M.handlers.addonUpdated = function(params)
  util.notify('Addon updated', 'INFO')
end

---@param msg RpcMessage
M.handle = function(msg)
  local handler = M.handlers[msg.type]
  if not handler then
    util.notify('Received unknown RPC message type: "' .. msg.type .. '"', 'ERROR')
    return
  end
  vim.schedule(function()
    handler(msg)
  end)
end

return M
