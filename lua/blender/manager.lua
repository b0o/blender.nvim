local notify = require 'blender.notify'

---@class Manager
---@field task Task?
local M = {
  task = nil,
}

---@param task Task
M.start_task = function(task)
  if M.has_running_task() then
    notify('A task is already running', 'ERROR')
    return
  end
  M.task = task
  M.task:start()
end

M.stop_task = function()
  if M.has_running_task() then
    M.task:stop()
  end
end

M.has_running_task = function()
  return M.task and M.task.status == 'running'
end

M.get_running_task = function()
  if M.has_running_task() then
    return M.task
  end
  return nil
end

return M
