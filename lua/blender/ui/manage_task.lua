local n = require 'nui-components'
local util = require 'blender.util'

local buffer = require 'blender.components.buffer'
local dap = require 'blender.dap'
local manager = require 'blender.manager'
local hl = require('blender.highlights').groups
-- local rpc = require 'blender.rpc'

local current_renderer

---@class ManageTaskProps
---@field task Task
---@field message? string

---@param props ManageTaskProps
return function(props)
  -- only allow one instance of the task manager
  if current_renderer then
    current_renderer:close()
    current_renderer = nil
  end

  local task = props.task

  ---@type {task_id: SignalValue<integer>, task_change_count: SignalValue<integer>, active_tab: SignalValue<'tab-output' | 'tab-debug'>}
  local signal = n.create_signal {
    task_id = props.task.id,
    task_change_count = 0,
    active_tab = 'tab-output',
  }
  local is_tab_active = n.is_active_factory(signal.active_tab)

  local on_change_listener
  local setup_on_change_listener = function()
    on_change_listener = task:on_change(vim.schedule_wrap(function()
      signal.task_change_count = signal.task_change_count:get_value() + 1
    end))
  end
  local clear_on_change_listener = function()
    if task and on_change_listener then
      task:off_change(on_change_listener)
    end
  end

  local renderer = n.create_renderer {
    width = math.min(vim.o.columns, 100),
    height = math.min(vim.o.lines, 29),
    on_mount = function()
      setup_on_change_listener()
    end,
    on_unmount = function()
      task:off_change(on_change_listener)
      current_renderer = nil
    end,
  }
  current_renderer = renderer

  renderer:add_mappings {
    {
      mode = { 'n', 'v' },
      key = '<C-x>',
      handler = function()
        task:stop()
      end,
    },
    {
      mode = { 'n', 'v' },
      key = '<C-r>',
      handler = function()
        util.notify('Restarting task', 'INFO')
        local new_task = task:clone()
        task:stop()
        clear_on_change_listener()
        task = new_task
        signal.task_id = task.id
        signal.task_change_count = 0
        setup_on_change_listener()
        manager.start_task(new_task)
      end,
    },
  }

  renderer:render(
    --
    n.rows(
      n.paragraph {
        is_focusable = false,
        lines = {
          props.message and n.line(n.text(' ', hl.BlenderAccent), n.text(props.message)) or nil,
        },
      },

      n.paragraph {
        is_focusable = false,
        border_label = {
          text = n.text('Blender Task Manager', hl.BlenderAccent),
          icon = '󰂫',
          align = 'center',
        },
        padding = { top = 0, right = -3, bottom = 0, left = 1 },
        truncate = true,
        lines = signal.task_change_count:map(function()
          local debugger_text
          if task.debugger_attached then
            debugger_text = 'Attached'
          elseif task.client then
            if task.client.debugpy_enabled then
              debugger_text = 'Not attached'
            elseif dap.is_available() then
              debugger_text = 'Disabled'
            else
              debugger_text = 'Disabled (missing nvim-dap)'
            end
          else
            debugger_text = 'N/a'
          end
          return {
            n.line(n.text('Id:       ', hl.BlenderAccent), tostring(task.id)),
            n.line(n.text('Profile:  ', hl.BlenderAccent), task.profile.name),
            n.line(n.text('Command:  ', hl.BlenderAccent), table.concat(task.cmd, ' ')),
            n.line(
              n.text('Status:   ', hl.BlenderAccent),
              task.status .. (task.exit_code and ' (code ' .. task.exit_code .. ')' or '')
            ),
            n.line(
              n.text('PID:      ', hl.BlenderAccent),
              tostring(task.status == 'running' and task:get_pid() or 'N/a')
            ),
            n.line(n.text('Debugger: ', hl.BlenderAccent), debugger_text),
          }
        end),
      },

      n.tabs(
        { active_tab = signal.active_tab },
        n.columns(
          { flex = 0 },
          n.button {
            label = '  Output <M-1> ',
            global_press_key = '<M-1>',
            is_active = is_tab_active 'tab-output',
            on_press = function()
              ---@type 'tab-output'
              signal.active_tab = 'tab-output'
            end,
          },
          n.gap(1),
          n.button {
            label = '  Debug Console <M-2> ',
            global_press_key = '<M-2>',
            is_active = is_tab_active 'tab-debug',
            on_press = function()
              ---@type 'tab-debug'
              signal.active_tab = 'tab-debug'
            end,
          }
        ),
        n.tab(
          { id = 'tab-output' },
          buffer {
            buf = signal.task_id:map(function()
              return task:get_buf()
            end),
            autoscroll = true,
            border_style = 'rounded',
            border_label = {
              text = n.text('Output', hl.BlenderAccent),
              icon = '',
              align = 'center',
            },
            size = 16,
          }
        ),
        n.tab(
          { id = 'tab-debug' },
          buffer {
            buf = signal.task_id:map(function()
              return dap.get_buf()
            end),
            autoscroll = true,
            border_style = 'rounded',
            border_label = {
              text = n.text('Debugger', hl.BlenderAccent),
              icon = '',
              align = 'center',
            },
            size = 16,
          }
        )
      ),

      n.paragraph {
        is_focusable = false,
        align = 'right',
        lines = {
          n.line(n.text('<C-x> Stop Task  <C-r> Restart Task', 'Comment')),
        },
      }
    )
  )
end
