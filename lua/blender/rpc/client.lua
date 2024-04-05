local curl = require 'plenary.curl'

-- TODO: This should be a part of RpcClientParams
local proto = 'http'
local host = 'localhost'

---@class RpcClientParams
---@field blender_port integer
---@field debugpy_port integer
---@field python_exe string
---@field blender_path string
---@field scripts_folder string
---@field path_mappings List<unknown>

---@class RpcClient : RpcClientParams
local RpcClient = {}

---@param params RpcClientParams
---@return RpcClient
function RpcClient.new(params)
  local self = setmetatable({
    blender_port = params.blender_port,
    debugpy_port = params.debugpy_port,
    python_exe = params.python_exe,
    blender_path = params.blender_path,
    scripts_folder = params.scripts_folder,
    path_mappings = params.path_mappings,
  }, { __index = RpcClient })
  return self
end

function RpcClient:_base_url()
  return string.format('%s://%s:%d', proto, host, self.blender_port)
end

---@param data any
function RpcClient:post(data)
  return curl.post(self:_base_url(), {
    body = vim.fn.json_encode(data),
    headers = {
      content_type = 'application/json',
    },
  })
end

function RpcClient:reload_addon()
  return self:post {
    type = 'reload',
    names = vim
      .iter(self.path_mappings)
      :map(function(mapping)
        return vim.fn.fnamemodify(mapping.load, ':t')
      end)
      :totable(),
  }
end

return RpcClient
