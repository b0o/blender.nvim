local util = require 'blender.util'

---@class TaskParams
---@field profile Profile
---@field cmd List<string>
---@field cwd string
---@field env table
---@field on_start? fun(Task): nil

---@class OutputLine
---@field data string
---@field channel 'stdout' | 'stderr'

---@class Task : TaskParams
---@field id integer
---@field private _job_id? integer
---@field private _bufnr? integer
---@field private _term_id? integer
---@field status 'waiting' | 'failed' | 'running' | 'exited'
---@field exit_code? integer
---@field output List<OutputLine>
---@field private _listeners table<number, fun(): nil>
---@field debugger_attached boolean
local Task = {}

local last_id = 0

---@param params TaskParams
---@return Task
function Task.new(params)
  last_id = last_id + 1
  return setmetatable({
    id = last_id,
    profile = params.profile,
    cmd = params.cmd,
    cwd = params.cwd,
    env = params.env,
    on_start = params.on_start,
    job_id = nil,
    _bufnr = nil,
    _term_id = nil,
    status = 'waiting',
    exit_code = nil,
    output = {},
    _listeners = {},
    debugger_attached = false,
  }, { __index = Task })
end

function Task:clone()
  return Task.new {
    profile = self.profile,
    cmd = vim.deepcopy(self.cmd),
    cwd = self.cwd,
    env = vim.deepcopy(self.env),
    on_start = self.on_start,
  }
end

---@param data List<string>
---@param channel 'stdout' | 'stderr'
function Task:_handle_output(data, channel)
  pcall(vim.api.nvim_chan_send, self._term_id, table.concat(data, '\r\n'))
  vim.defer_fn(function()
    util.terminal_tail_hack(self:get_buf())
  end, 10)
end

--- Based on Overseer's jobstart strategy implementation:
--- https://github.com/stevearc/overseer.nvim/blob/b04b0b105c07b4f02b3073ea3a98d6eca90bf152/lua/overseer/strategy/jobstart.lua#L48
---Copyright (c) 2024 Steven Arcangeli
---MIT License
function Task:get_buf()
  if not self._bufnr or not vim.api.nvim_buf_is_valid(self._bufnr) then
    self._bufnr = vim.api.nvim_create_buf(false, true)
    local mode = vim.api.nvim_get_mode().mode
    local term_id
    util.buf_run_in_sized_win(self._bufnr, {
      width = vim.o.columns,
      height = vim.o.lines,
    }, function()
      term_id = vim.api.nvim_open_term(self._bufnr, {
        on_input = function(_, _, _, data)
          pcall(vim.api.nvim_chan_send, self._job_id, data)
          vim.defer_fn(function()
            util.terminal_tail_hack(self._bufnr)
          end, 10)
        end,
      })
    end)
    self._term_id = term_id
    util.hack_around_termopen_autocmd(mode)
  end
  return self._bufnr
end

function Task:start()
  if self.status ~= 'waiting' then
    util.notify('Task has already been started', 'WARN')
    return
  end
  self:get_buf()
  local res = vim.fn.jobstart(self.cmd, {
    cwd = self.cwd,
    env = vim.tbl_extend('force', {
      BLENDER_NVIM_TASK_ID = tostring(self.id),
    }, self.env),
    on_exit = function(_, code)
      self.status = 'exited'
      self.exit_code = code
      self._job_id = nil
      self.debugger_attached = false
      if code == 0 then
        util.notify('Task completed successfully', 'INFO')
      else
        util.notify('Task exited with code: ' .. code, 'ERROR')
      end
      self:_emit_on_change()
    end,
    pty = true,
    on_stdout = function(_, data, _)
      self:_handle_output(data, 'stdout')
    end,
    on_stderr = function(_, data, _)
      self:_handle_output(data, 'stderr')
    end,
  })

  if res == 0 then
    util.notify('Failed to start task: invalid arguments or job table is full', 'ERROR')
    self.status = 'failed'
    return
  end
  if res == -1 then
    util.notify('Failed to start task: command is not executable', 'ERROR')
    self.status = 'failed'
    return
  end
  self._job_id = res
  self.status = 'running'

  if self.on_start then
    self.on_start(self)
  end
end

function Task:get_pid()
  if self.status ~= 'running' or not self._job_id then
    return
  end
  local ok, pid = pcall(vim.fn.jobpid, self._job_id)
  if not ok then
    return
  end
  return pid
end

function Task:stop()
  if self.status ~= 'running' then
    util.notify('Task is not running', 'WARN')
    return
  end
  vim.fn.jobstop(self._job_id)
end

function Task:_emit_on_change()
  for _, fn in pairs(self._listeners) do
    fn()
  end
end

function Task:on_change(fn)
  local id = #self._listeners + 1
  self._listeners[id] = fn
  return id
end

function Task:off_change(id)
  self._listeners[id] = nil
end

function Task:attach_debugger()
  self.debugger_attached = true
  self:_emit_on_change()
end

--TODO: Detect debugger detaching

return Task
