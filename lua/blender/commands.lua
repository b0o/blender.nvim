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
  cmd('BlenderLaunch', action 'show_launcher', 'Launch a Blender profile')
  cmd('BlenderManage', action 'show_task_manager', 'Manage a running Blender task')
  --TODO: Remove
  cmd('BlenderTest', action 'show_test', 'Blender test command')
end

return M
