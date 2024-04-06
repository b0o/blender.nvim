---@class Manager
---@field task Task?
local M = {
  task = nil,
}

---@param task Task
M.start_task = function(task)
  if M.has_running_task() then
    M.stop_task()
  end
  M.task = task
  M.task:start()
end

M.stop_task = function()
  if M.has_running_task() then
    M.task:stop()
  end
  M.task = nil
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

---@param task_id integer
---@param client RpcClient
M.attach = function(task_id, client)
  local running_task = M.get_running_task()
  if not running_task or running_task.id ~= task_id then
    return
  end
  running_task:attach_client(client)
end

return M
