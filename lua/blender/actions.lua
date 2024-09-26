local ui = require 'blender.ui'
local manager = require 'blender.manager'
local notify = require 'blender.notify'
local manage_task = require 'blender.ui.manage_task'
local select_profile = require 'blender.ui.select_profile'

local M = {}

---Open the Blender.nvim UI
M.show_ui = function()
  local running_task = manager.get_running_task()
  if running_task then
    M.show_task_manager()
    return
  end
  M.show_launcher()
end

M.close_ui = function()
  ui.close()
end

M.toggle_ui = function()
  if ui.is_open() then
    ui.close()
  else
    M.show_ui()
  end
end

---Launch a Blender profile
M.show_launcher = function()
  local running_task = manager.get_running_task()
  if running_task then
    manage_task {
      message = 'A task is already running',
      task = running_task,
    }
    return
  end
  select_profile(function(profile)
    local task = profile:launch()
    if not task then
      return
    end
    manage_task { task = task }
  end)
end

---Manage a running Blender task
M.show_task_manager = function()
  if not manager.task then
    notify('No Blender task', 'ERROR')
    return
  end
  manage_task { task = manager.task }
end

---Reload the Blender add-on
M.reload = function()
  local running_task = manager.get_running_task()
  if not running_task then
    notify('No running blender task', 'ERROR')
    return
  end
  if not running_task.client then
    notify('No RPC client attached to the running task', 'ERROR')
    return
  end
  running_task.client:reload_addon()
end

---Start watching for changes in the addon files
---Note: When the task exits, the watch is removed.
---@param patterns? string|string[] # pattern(s) matching files to watch for changes
M.watch = function(patterns)
  local running_task = manager.get_running_task()
  if not running_task then
    notify('No running blender task', 'ERROR')
    return
  end
  running_task:watch(patterns or running_task.profile:get_watch_patterns())
end

---Stop watching for changes in the addon files
M.unwatch = function()
  local running_task = manager.get_running_task()
  if not running_task then
    notify('No running blender task', 'ERROR')
    return
  end
  running_task:unwatch()
end

return M
