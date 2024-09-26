local n = require 'nui-components'

local config = require 'blender.config'
local hl = require('blender.highlights').groups
local Profile = require 'blender.profile'
local ui = require 'blender.ui'

local instance

---@param on_select fun(profile: Profile): nil
local function SelectProfile(on_select)
  if instance then
    instance:close()
    instance = nil
    ui._on_close()
  end

  local renderer = n.create_renderer {
    width = math.min(vim.o.columns, 64),
    height = math.min(vim.o.lines, 20),
  }

  renderer:on_mount(function()
    instance = renderer
    ui._on_open {
      close = function()
        if instance then
          instance:close()
          instance = nil
        end
      end,
    }
  end)
  renderer:on_unmount(function()
    instance = nil
    ui._on_close()
  end)

  if #config.profiles == 0 then
    renderer:render(n.rows(
      n.paragraph {
        border_label = {
          text = n.text('No Profiles Found', hl.BlenderAccent),
          icon = '⚠ ',
          align = 'center',
        },
        padding = { top = 0, right = 1, bottom = 0, left = 1 },
        truncate = false,
        lines = {
          n.line 'Please ensure that Blender is installed, or add a custom profile to your configuration.',
          n.line '',
        },
      },
      n.columns(
        { flex = 0 },
        n.gap { flex = 1 },
        n.button {
          label = ' Close ',
          autofocus = true,
          is_active = true,
          on_press = function()
            renderer:close()
          end,
        },
        n.gap { flex = 1 }
      )
    ))
    return
  end

  ---@type List<{id: number, profile: Profile}>
  local options = vim
    .iter(ipairs(config.profiles))
    :map(function(i, profile)
      return { id = i, profile = Profile.create(profile) }
    end)
    :totable()

  ---@type {selected: SignalValue<Profile>}
  local signal = n.create_signal { selected = options[1].profile }

  local body = function()
    return n.rows(
      n.paragraph {
        is_focusable = false,
        border_label = {
          text = n.text('Blender Profile', hl.BlenderAccent),
          icon = '󰂫',
          align = 'center',
        },
        padding = { top = 0, right = 1, bottom = 0, left = 1 },
        truncate = true,
        lines = signal.selected:map(function(profile)
          local res = {
            n.line(n.text('Name:       ', hl.BlenderAccent), profile.name),
            n.line(n.text('Command:    ', hl.BlenderAccent), table.concat(profile:get_full_cmd() or {}, ' ')),
          }
          if profile.enable_dap ~= nil then
            table.insert(
              res,
              n.line(n.text('DAP:        ', hl.BlenderAccent), profile.enable_dap and 'enabled' or 'disabled')
            )
          end
          return res
        end),
      },
      n.select {
        flex = 5,

        data = vim
          .iter(options)
          :map(function(option)
            ---@cast option {id: number, profile: Profile}
            return n.option(
              n.line(n.text('󰂫', hl.BlenderAccent), ' ', n.text(option.profile.name)),
              { id = option.id }
            )
          end)
          :totable(),

        autofocus = true,
        multiselect = false,

        padding = { top = 0, right = 1, bottom = 0, left = 1 },
        size = math.max(4, math.min(8, #options)),

        on_change = function(node)
          ---@cast node {id: number}
          local selected = options[node.id]
          if selected == nil then
            return
          end
          ---@cast selected {id: number, profile: Profile}
          signal.selected = selected.profile
        end,

        on_select = function(node)
          ---@cast node {id: number}
          local selected = options[node.id]
          if selected == nil then
            return
          end
          renderer:close()
          ---@cast selected {id: number, profile: Profile}
          on_select(selected.profile)
        end,

        mappings = function(component)
          local function action(name)
            return function()
              local actions = component:get_actions()
              actions[name]()
            end
          end
          local mode = { 'i', 'n', 'v' }
          return {
            { mode = mode, key = '<C-n>', handler = action 'on_focus_next' },
            { mode = mode, key = '<C-p>', handler = action 'on_focus_prev' },
            { mode = mode, key = '<Tab>', handler = action 'on_focus_next' },
            { mode = mode, key = '<S-Tab>', handler = action 'on_focus_prev' },
          }
        end,
      },

      n.paragraph {
        is_focusable = false,
        align = 'right',
        lines = {
          n.line(n.text('<Cr> Select  <Esc> Cancel', 'Comment')),
        },
      }
    )
  end

  renderer:render(body)
end

return SelectProfile
