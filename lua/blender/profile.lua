local manager = require 'blender.manager'
local Task = require 'blender.task'
local rpc = require 'blender.rpc'
local util = require 'blender.util'
local dap = require 'blender.dap'
local config = require 'blender.config'

---@class ProfileParams
---@field name string # The name of the profile
---@field cmd string | List<string> # The command to run
---@field use_launcher? boolean # Whether to append the launcher script to the command
---@field extra_args? List<string> # Extra arguments to pass to the command
---@field enable_dap? boolean # Whether to enable debugging with DAP

---@class Profile : ProfileParams
---@field cmd List<string>
-- -@field enable_dap boolean
local Profile = {}

local launcher = 'launch_blender.py'

local get_launcher_path = function()
  local launcher_path = vim.api.nvim_get_runtime_file(launcher, false)
  if not launcher_path or #launcher_path == 0 then
    util.notify('Could not find launcher script: ' .. launcher, 'ERROR')
    return nil
  end
  return launcher_path[1]
end

---@param params ProfileParams
---@return Profile
function Profile.new(params)
  vim.validate {
    name = { params.name, 'string' },
    cmd = { params.cmd, { 'string', 'table' } },
    use_launcher = { params.use_launcher, 'boolean', true },
    extra_args = { params.extra_args, 'table', true },
    enable_dap = { params.enable_dap, 'boolean', true },
  }
  ---@type List<string>
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
  }, { __index = Profile })
end

---@return List<string>
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
  ---@type List<string>
  local launch_cmd = {}
  vim.list_extend(launch_cmd, self.cmd)
  vim.list_extend(launch_cmd, args)
  return launch_cmd
end

local function is_addon_init(path)
  if vim.fn.filereadable(path) == 0 then
    return false
  end
  local content = vim.fn.readfile(path)
  return vim.tbl_filter(function(line)
    return line:find 'bl_info' ~= nil
  end, content)
end

function Profile:find_addon_dir()
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

---@return List<PathMapping>
function Profile:get_path_mappings()
  local load_dir = self:find_addon_dir()
  if not load_dir then
    util.notify('Could not find addon directory', 'WARN')
    return {}
  end
  local module_name = vim.fn.fnamemodify(load_dir, ':t')
  return {
    {
      load_dir = load_dir,
      module_name = module_name,
    },
  }
end

function Profile:launch()
  local launch_cmd = self:get_full_cmd()
  if not launch_cmd then
    return
  end
  local path_mappings = self:get_path_mappings()
  local enable_dap
  if not dap.is_available() then
    enable_dap = false
  elseif self.enable_dap ~= nil then
    enable_dap = self.enable_dap
  else
    enable_dap = config.dap.enabled
  end
  local task = Task.new {
    cmd = launch_cmd,
    cwd = vim.fn.getcwd(),
    env = vim.tbl_extend('force', vim.fn.environ(), {
      ENABLE_DEBUGPY = enable_dap and 'yes' or 'no',
      ADDONS_TO_LOAD = vim.json.encode(path_mappings),
      EDITOR_ADDR = rpc.get_server():get_addr(),
      ALLOW_MODIFY_EXTERNAL_PYTHON = 'no',
    }),
    profile = self,
  }
  manager.start_task(task)
  return task
end

return Profile
