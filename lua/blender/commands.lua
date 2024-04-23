local M = {}

local a = vim.api

local action = function(name, ...)
  local args = { ... }
  return function()
    return require('blender.actions')[name](unpack(args))
  end
end

local cmd = function(name, fn, desc, opts)
  a.nvim_create_user_command(
    name,
    fn,
    vim.tbl_extend('force', {
      force = true,
      desc = desc,
    }, opts or {})
  )
end

M.setup = function()
  cmd('Blender', action 'show_ui', 'Open the Blender.nvim UI')
  cmd('BlenderLaunch', action 'show_launcher', 'Launch a Blender profile')
  cmd('BlenderManage', action 'show_task_manager', 'Manage a running Blender task')
  cmd('BlenderReload', action 'reload', 'Reload the Blender addon')
  cmd('BlenderWatch', action 'watch', 'Watch for changes and reload the addon')
  cmd('BlenderUnwatch', action 'unwatch', 'Stop watching for changes')
end

return M
