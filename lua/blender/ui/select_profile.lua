local n = require 'nui-components'

local config = require 'blender.config'
local hl = require('blender.highlights').groups

local current_renderer

---@param on_select fun(profile: Profile): nil
return function(on_select)
  -- only allow one instance of the profile selector
  if current_renderer then
    current_renderer:close()
    current_renderer = nil
  end

  local renderer = n.create_renderer {
    width = math.min(vim.o.columns, 64),
    height = math.min(vim.o.lines, 20),
    on_unmount = function()
      current_renderer = nil
    end,
  }
  current_renderer = renderer

  ---@type List<{id: number, profile: Profile}>
  local options = vim
    .iter(ipairs(config.blender.profiles))
    :map(function(i, profile)
      return { id = i, profile = profile }
    end)
    :totable()

  ---@type {selected: SignalValue<Profile>}
  local signal = n.create_signal { selected = options[1].profile }

  renderer:render(
    --
    n.rows(

      n.paragraph {
        is_focusable = false,
        border_label = {
          text = n.text('Blender Profile', hl.BlenderAccent),
          icon = '󰂫',
          align = 'center',
        },
        padding = { top = 0, right = -3, bottom = 0, left = 1 },
        truncate = true,
        lines = signal.selected:map(function(profile)
          return {
            n.line(n.text('Name:       ', hl.BlenderAccent), profile.name),
            n.line(n.text('Command:    ', hl.BlenderAccent), table.concat(profile:get_full_cmd() or {}, ' ')),
          }
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
  )
end
