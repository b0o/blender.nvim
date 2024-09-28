local manager = require 'blender.manager'
local RpcClient = require 'blender.rpc.client'
local notify = require 'blender.notify'

local M = {
  ---@type Server?
  server = nil,
}

---@class Server
---@field socket? string
local Server = {}

function Server.create()
  local self = setmetatable({
    addr = nil,
    id = nil,
  }, { __index = Server })
  return self
end

function Server:start()
  if self.socket == nil then
    self.socket = vim.fn.serverstart()
  end
end

function Server:stop()
  if self.socket ~= nil then
    vim.fn.serverstop(self.socket)
    self.socket = nil
  end
end

function Server:get_socket()
  if self.socket == nil then
    self:start()
  end
  return self.socket
end

M.get_server = function()
  if M.server == nil then
    M.server = Server.create()
  end
  return M.server
end

M.handlers = {}

---@class RpcMessage
---@field type 'setup' | 'setup_debugpy' | 'addon_updated' | 'enable_failure' | 'disable_failure'

---@class RpcSetupParams : RpcMessage
---@field type 'setup'
---@field python_exe string
---@field blender_path string
---@field blender_version string
---@field scripts_folder string
---@field path_mappings unknown[]
---@field task_id string
---@field channel_id number

---@param params RpcSetupParams
M.handlers.setup = function(params)
  vim.validate {
    python_exe = { params.python_exe, 'string' },
    blender_path = { params.blender_path, 'string' },
    blender_version = { params.blender_version, 'string' },
    scripts_folder = { params.scripts_folder, 'string' },
    path_mappings = { params.path_mappings, 'table' },
    task_id = { params.task_id, 'number' },
    channel_id = { params.channel_id, 'number' },
  }
  local rpc_client = RpcClient.create {
    python_exe = params.python_exe,
    blender_path = params.blender_path,
    blender_version = params.blender_version,
    scripts_folder = params.scripts_folder,
    path_mappings = params.path_mappings,
    channel_id = params.channel_id,
  }
  local running_task = manager.get_running_task()
  if not running_task then
    notify('No running Blender task', 'ERROR')
    return
  end
  if running_task.id ~= params.task_id then
    notify('Received setup message for an unknown task: ' .. params.task_id, 'ERROR')
    return
  end
  running_task:attach_client(rpc_client)
end

---@class RpcSetupDebugpyParams : RpcMessage
---@field type 'setup_debugpy'
---@field host string
---@field port number

---@param params RpcSetupDebugpyParams
M.handlers.setup_debugpy = function(params)
  vim.validate {
    host = { params.host, 'string' },
    port = { params.port, 'number' },
  }
  local running_task = manager.get_running_task()
  --TODO: Add task_id to the message
  -- if running_task and running_task.id == task_id then
  if running_task then
    running_task:attach_debugger {
      host = params.host,
      port = params.port,
    }
  end
end

---@class RpcAddonUpdatedParams : RpcMessage
---@field type 'addon_updated'

---@param params RpcAddonUpdatedParams
M.handlers.addon_updated = function(params)
  local _ = params
  notify('Addon updated', 'TRACE')
end

---@class RpcEnableFailureParams : RpcMessage
---@field type 'enable_failure'
---@field message string

---@param params RpcEnableFailureParams
M.handlers.enable_failure = function(params)
  notify('Failed to enable the Blender addon: ' .. params.message, 'ERROR')
end

---@class RpcDisableFailureParams : RpcMessage
---@field type 'disable_failure'
---@field message string

---@param params RpcDisableFailureParams
M.handlers.disable_failure = function(params)
  notify('Failed to disable the Blender addon: ' .. params.message, 'ERROR')
end

---@param msg RpcMessage
M.handle = function(msg)
  local handler = M.handlers[msg.type]
  if not handler then
    notify('Received unknown RPC message type: "' .. msg.type .. '"', 'ERROR')
    return
  end
  vim.schedule(function()
    handler(msg)
  end)
end

return M
