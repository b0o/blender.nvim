---@class RpcClientParams
---@field python_exe string
---@field blender_path string
---@field blender_version string
---@field scripts_folder string
---@field path_mappings List<unknown>
---@field channel_id number

---@class RpcClient : RpcClientParams
local RpcClient = {}

---@param params RpcClientParams
---@return RpcClient
function RpcClient.create(params)
  local self = setmetatable({
    python_exe = params.python_exe,
    blender_path = params.blender_path,
    blender_version = params.blender_version,
    scripts_folder = params.scripts_folder,
    path_mappings = params.path_mappings,
    channel_id = params.channel_id,
  }, { __index = RpcClient })
  return self
end

---@param name string
---@param ... any
function RpcClient:request(name, ...)
  vim.fn.rpcrequest(self.channel_id, name, ...)
end

---@param name string
---@param ... any
function RpcClient:notify(name, ...)
  vim.fn.rpcnotify(self.channel_id, name, ...)
end

function RpcClient:reload_addon()
  return self:notify('reload', {
    names = vim
      .iter(self.path_mappings)
      :map(function(mapping)
        return vim.fn.fnamemodify(mapping.load, ':t')
      end)
      :totable(),
  })
end

return RpcClient
