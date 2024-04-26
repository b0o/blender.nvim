local Signal = require 'nui-components.signal'

local utils = require 'blender.utils'
local signal_utils = require 'blender.signal.utils'
local dap = require 'blender.dap'
local notify = require 'blender.notify'

local augroup = vim.api.nvim_create_augroup('blender.task', { clear = true })

---@alias TaskEventType 'change' | 'start' | 'start_fail' | 'client_attach' | 'dap_attach' | 'dap_repl_buf_set' | 'exit'

---@class TaskEvent
---@field type TaskEventType
---@field id integer
---@field prime boolean
---@field task Task

---@alias TaskStatus 'waiting' | 'failed' | 'running' | 'exited'

---@class TaskSignal
---@field change SignalValue<TaskEvent>
---@field start SignalValue<TaskEvent>
---@field start_fail SignalValue<TaskEvent>
---@field client_attach SignalValue<TaskEvent>
---@field dap_attach SignalValue<TaskEvent>
---@field dap_repl_buf_set SignalValue<TaskEvent>
---@field exit SignalValue<TaskEvent>

---@class TaskParams
---@field profile Profile
---@field cmd List<string>
---@field cwd string
---@field env table

---@class TaskWatchStatus
---@field autocmd_id integer
---@field pattern string[]

---@class Task : TaskParams
---@field id integer
---@field status TaskStatus
---@field client? RpcClient
---@field exit_code? integer
---@field debugger_attached boolean
---@field dap_repl_buf? integer
---@field watch_status? TaskWatchStatus
---@field _next_event_id integer
---@field private _signal TaskSignal
---@field private _job_id? integer
---@field private _bufnr? integer
---@field private _term_id? integer
local Task = {}

local next_id = 1

---@param params TaskParams
---@return Task
function Task.create(params)
  local id = next_id
  next_id = next_id + 1

  return setmetatable({
    id = id,

    profile = params.profile,
    cmd = params.cmd,
    cwd = params.cwd,
    env = params.env,

    status = 'waiting',
    client = nil,
    exit_code = nil,
    debugger_attached = false,
    dap_repl_buf = nil,
    watch = nil,

    _next_event_id = 1,
    _signal = Signal.create {
      change = nil,
      start = nil,
      start_fail = nil,
      client_attach = nil,
      dap_attach = nil,
      exit = nil,
    },
    _job_id = nil,
    _bufnr = nil,
    _term_id = nil,
  }, { __index = Task })
end

---@class TaskOnParams
---@field prime? boolean Whether to "prime" the signal; if true, will be immediately "primed" with nil as the first event

---@param event TaskEventType
---@param params? TaskOnParams
---@return SignalValue<TaskEvent>
function Task:on(event, params)
  params = params or {}
  ---@type SignalValue<Task>
  local signal_value = self._signal[event]
  return signal_value
    :map(function(evt)
      if evt == nil then
        return {
          type = event,
          id = -1,
          prime = true,
          task = self,
        }
      end
      return evt
    end)
    :filter(function(val)
      return params.prime == true or not val.prime
    end)
end

---@param event TaskEventType
---@param fn fun(val: Task): nil
---@return SignalValue<TaskEvent>
function Task:once(event, fn)
  return signal_utils.observe_once(self:on(event), fn)
end

---@param event TaskEventType|(TaskEventType | nil | boolean)[]
function Task:_dispatch(event)
  local events = type(event) == 'table' and event or { event }
  for _, evt in pairs(events) do
    if type(evt) == 'string' then
      self._signal[evt] = {
        type = evt,
        id = self._next_event_id,
        prime = false,
        task = self,
      }
      self._next_event_id = self._next_event_id + 1
    end
  end
end

---@param data List<string>
function Task:_handle_output(data)
  pcall(vim.api.nvim_chan_send, self._term_id, table.concat(data, '\r\n'))
  vim.defer_fn(function()
    utils.terminal_tail_hack(self:get_buf())
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
    utils.buf_run_in_sized_win(self._bufnr, {
      width = vim.o.columns,
      height = vim.o.lines,
    }, function()
      term_id = vim.api.nvim_open_term(self._bufnr, {
        on_input = function(_, _, _, data)
          pcall(vim.api.nvim_chan_send, self._job_id, data)
          vim.defer_fn(function()
            utils.terminal_tail_hack(self._bufnr)
          end, 10)
        end,
      })
    end)
    self._term_id = term_id
    utils.hack_around_termopen_autocmd(mode)
  end
  return self._bufnr
end

function Task:start()
  if self.status ~= 'waiting' then
    notify('Task has already been started', 'WARN')
    return
  end
  self:get_buf()
  local res = vim.fn.jobstart(self.cmd, {
    cwd = self.cwd,
    env = vim.tbl_extend('force', {
      BLENDER_NVIM_TASK_ID = tostring(self.id),
    }, self.env),
    on_exit = function(_, code)
      vim.schedule(function()
        self.status = 'exited'
        self.exit_code = code
        self._job_id = nil
        self.debugger_attached = false
        if code == 0 then
          notify('Task completed successfully', 'TRACE')
        else
          notify('Task exited with code: ' .. code, 'ERROR')
        end
        self:_dispatch { 'change', 'exit' }
      end)
    end,
    pty = true,
    on_stdout = function(_, data, _)
      self:_handle_output(data)
    end,
    on_stderr = function(_, data, _)
      self:_handle_output(data)
    end,
  })
  if res == 0 then
    notify('Failed to start task: invalid arguments or job table is full', 'ERROR')
    self.status = 'failed'
    self:_dispatch { 'change', 'start_fail' }
    return
  end
  if res == -1 then
    notify('Failed to start task: command is not executable', 'ERROR')
    self.status = 'failed'
    self:_dispatch { 'change', 'start_fail' }
    return
  end
  self._job_id = res
  self.status = 'running'
  self:_dispatch { 'change', 'start' }
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
    notify('Task is not running', 'WARN')
    return
  end
  vim.fn.jobstop(self._job_id)
end

---@param client RpcClient
function Task:attach_client(client)
  self.client = client
  self:_dispatch { 'change', 'client_attach' }
end

---@param params { host: string, port: number }
function Task:attach_debugger(params)
  if not self.client then
    notify("Can't attach debugger: No RPC client attached to the task", 'ERROR')
    return
  end
  local dap_attached = require('blender.dap').attach {
    host = params.host,
    port = params.port,
    python_exe = self.client.python_exe,
    cwd = self.client.scripts_folder,
    path_mappings = self.client.path_mappings,
  }
  if dap_attached then
    notify('Debugger attached', 'TRACE')
    -- for some reason, we need to defer this in order for the injected syntax highlighting
    -- to work, and using vim.schedule() doesn't work
    self:_dispatch { 'change', 'dap_attach' }
    self.debugger_attached = true
    self:get_dap_repl_buf()
  end
end

--BUG: If the dap repl buffer is deleted, re-creating it doesn't work as expected
function Task:get_dap_repl_buf()
  if not self.debugger_attached then
    return dap.get_fallback_repl_buf()
  end
  if self.dap_repl_buf and vim.api.nvim_buf_is_valid(self.dap_repl_buf) then
    return self.dap_repl_buf
  end
  vim.defer_fn(function()
    local repl_buf = dap.get_repl_buf()
    if not repl_buf or not vim.api.nvim_buf_is_valid(repl_buf) then
      return dap.get_fallback_repl_buf()
    end
    self.dap_repl_buf = repl_buf
    self:_dispatch { 'change', 'dap_repl_buf_set' }
  end, 0)
  return dap.get_fallback_repl_buf()
end

--TODO: Detect client/debugger detach

---Watch for changes, sending a reload command to the client when a
---buffer matching the pattern is written.
---@param pattern string|string[]
function Task:watch(pattern)
  local pattern_list = type(pattern) == 'table' and pattern or { pattern }
  if self.watch_status ~= nil then
    --TODO: Determine whether we should keep this behavior or re-create the autocmd (might be useful if the user wants to change the watch pattern)
    --TODO: check if autocmd is still valid
    notify('Already watching for changes', 'WARN')
    return
  end
  if self.status == 'waiting' then
    self:once('start', function()
      notify('Task started, setting up watch', 'ERROR')
      self:watch(pattern_list)
    end)
    return
  end
  if self.status ~= 'running' then
    notify('Cannot setup watch for ' .. self.status .. ' task', 'WARN')
    return
  end
  --TODO: Make event(s) configurable
  local autocmd_id = vim.api.nvim_create_autocmd('BufWritePost', {
    group = augroup,
    pattern = pattern_list,
    callback = function()
      if self.status ~= 'running' then
        return true -- remove the autocmd
      end
      if self.client then
        self.client:reload_addon()
      end
    end,
  })
  self:once('exit', function()
    self:unwatch()
  end)
  self.watch_status = {
    autocmd_id = autocmd_id,
    pattern = pattern_list,
  }
  notify('Watching for changes in ' .. table.concat(pattern_list, ', '), 'TRACE')
  self:_dispatch 'change'
end

function Task:unwatch()
  if self.watch_status == nil then
    notify('Not watching for changes', 'WARN')
    return
  end
  vim.api.nvim_del_autocmd(self.watch_status.autocmd_id)
  self.watch_status = nil
  notify('Stopped watching for changes', 'TRACE')
  self:_dispatch 'change'
end

return Task
