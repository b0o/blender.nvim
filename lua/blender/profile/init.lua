local manager = require 'blender.manager'
local Task = require 'blender.task'
local rpc = require 'blender.rpc'
local dap = require 'blender.dap'
local config = require 'blender.config'
local notify = require 'blender.notify'

---@class ProfileParams
---@field name string # The name of the profile
---@field cmd string | string[] # The command to run
---@field use_launcher? boolean # Whether to append the launcher script to the command
---@field extra_args? string[] # Extra arguments to pass to the command
---@field enable_dap? boolean # Whether to enable debugging with DAP
---@field watch? boolean # Whether to watch for changes and reload the addon

---@class Profile : ProfileParams
---@field cmd string[]
local Profile = {}

local launcher = 'launcher.py'

local get_launcher_path = function()
  local launcher_path = vim.api.nvim_get_runtime_file(launcher, false)
  if not launcher_path or #launcher_path == 0 then
    notify('Could not find launcher script: ' .. launcher, 'ERROR')
    return nil
  end
  return launcher_path[1]
end

local fix_path_separators = function(path)
  -- Windows paths get mixed up, ensure they have consistent separators
  return vim.fn.has 'win32' == 1 and string.gsub(path, '\\', '/') or path
end

---@param params ProfileParams
---@return Profile
function Profile.create(params)
  vim.validate {
    name = { params.name, 'string' },
    cmd = { params.cmd, { 'string', 'table' } },
    use_launcher = { params.use_launcher, 'boolean', true },
    extra_args = { params.extra_args, 'table', true },
    enable_dap = { params.enable_dap, 'boolean', true },
    watch = { params.watch, 'boolean', true },
  }
  ---@type string[]
  local cmd = type(params.cmd) == 'table' and params.cmd or { params.cmd }
  for _, c in ipairs(cmd) do
    vim.validate {
      cmd = { c, 'string' },
    }
  end
  if params.extra_args ~= nil then
    for _, arg in ipairs(params.extra_args) do
      vim.validate {
        arg = { arg, 'string' },
      }
    end
  end
  local use_launcher = params.use_launcher
  if use_launcher == nil then
    use_launcher = true
  end
  return setmetatable({
    name = params.name,
    cmd = cmd,
    use_launcher = use_launcher,
    extra_args = params.extra_args,
    enable_dap = params.enable_dap,
    watch = params.watch,
  }, { __index = Profile })
end

---@return string[]
function Profile:get_launch_args()
  local args = {}
  if self.use_launcher then
    local launcher_path = get_launcher_path()
    if not launcher_path then
      return nil
    end
    vim.list_extend(args, { '--python', launcher_path })
  end
  if self.extra_args then
    vim.list_extend(args, self.extra_args)
  end
  return args
end

function Profile:get_full_cmd()
  local args = self:get_launch_args()
  if not args then
    return
  end
  ---@type string[]
  local launch_cmd = {}
  vim.list_extend(launch_cmd, self.cmd)
  vim.list_extend(launch_cmd, args)
  return launch_cmd
end

local function is_addon_init(path)
  path = fix_path_separators(path)
  if vim.fn.filereadable(path) == 0 then
    return false
  end
  local content = vim.fn.readfile(path)
  return vim.tbl_filter(function(line)
    return line:find 'bl_info' ~= nil
  end, content)
end

function Profile:find_addon_dir()
  --TODO: Make add-on detection more configurable
  local cwd = vim.fn.getcwd()
  local addon_dir = cwd
  if is_addon_init(vim.fn.fnamemodify(cwd, ':p') .. '/__init__.py') then
    return cwd
  end
  for _, dir in ipairs(vim.fn.globpath(cwd, '*', true, true)) do
    if is_addon_init(dir .. '/__init__.py') then
      addon_dir = dir
      break
    end
  end
  return addon_dir
end

---@class PathMapping
---@field load_dir string
---@field module_name string

---@return {addon_dir: string, path_mappings: PathMapping[]}
function Profile:get_paths()
  local addon_dir = self:find_addon_dir()
  if not addon_dir then
    notify('Could not find addon directory', 'WARN')
    return {}
  end
  local module_name = vim.fn.fnamemodify(addon_dir, ':t')
  return {
    addon_dir = addon_dir,
    path_mappings = {
      {
        load_dir = addon_dir,
        module_name = module_name,
      },
    },
  }
end

function Profile:get_watch_patterns()
  local paths = self:get_paths()
  -- TODO: Make this configurable
  local addon_dir = fix_path_separators(paths.addon_dir)
  return { addon_dir .. '/*' }
end

function Profile:dap_enabled()
  if not dap.is_available() then
    return false
  end
  if self.enable_dap ~= nil then
    return self.enable_dap
  end
  return config.dap.enabled
end

function Profile:launch()
  local launch_cmd = self:get_full_cmd()
  if not launch_cmd then
    return
  end
  local task = Task.create {
    cmd = launch_cmd,
    cwd = vim.fn.getcwd(),
    env = vim.tbl_extend('force', vim.fn.environ(), {
      BLENDER_NVIM_ENABLE_DAP = self:dap_enabled() and 'yes' or 'no',
      BLENDER_NVIM_ADDONS_TO_LOAD = vim.json.encode(self:get_paths().path_mappings),
      BLENDER_NVIM_RPC_SOCKET = rpc.get_server():get_socket(),
    }),
    profile = self,
  }
  manager.start_task(task)
  if self.watch or (self.watch == nil and config.watch.enabled) then
    task:watch(self:get_watch_patterns())
  end
  return task
end

return Profile
