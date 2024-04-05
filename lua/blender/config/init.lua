local Profile = require 'blender.profile'
local Schema = require 'blender.config.schema'
local vx = require 'blender.config.validate'
local tx = require 'blender.config.transform'

local M = {}

---@class Config
---@field blender BlenderConfig

---@class BlenderConfig
---@field profiles List<ProfileParams>

---@class BlenderConfigResult
---@field profiles List<Profile>

---@class ConfigResult : Config
---@field blender BlenderConfigResult

---@class ConfigModule : ConfigResult
---@field setup fun(config: Config)
---@field reset fun()
---@field schema table

M.schema = Schema(function(s)
  return {
    blender = {
      profiles = s:entry(
        {
          { name = 'blender', cmd = '/usr/bin/blender' },
          {
            name = 'blender (headless)',
            cmd = '/usr/bin/blender',
            extra_args = { '--background', '--python-expr', 'breakpoint()' },
          },
          { name = 'ipython REPL', cmd = 'ipython', use_launcher = false },
          { name = 'python REPL', cmd = 'python', use_launcher = false },
          { name = 'qalc', cmd = 'qalc', use_launcher = false },
          -- { name = 'Blender 4.1', cmd = '/usr/bin/blender-4.1' },
          -- { name = 'Blender 4.2 (Beta)', cmd = '/usr/bin/blender-4.2' },
          -- { name = 'Blender 4.3 (Alpha)', cmd = '/usr/bin/blender-4.3' },
        },
        vx.list.of(vx.table.of_all {
          name = vx.string,
          cmd = vx.any { vx.string, vx.list.of(vx.string) },
          use_launcher = vx.optional(vx.bool),
          extra_args = vx.optional(vx.list.of(vx.string)),
        }),
        {
          transform = function(val, entry)
            local extended = tx.extend(val, entry)
            local res = {}
            for _, profile in ipairs(extended) do
              table.insert(res, Profile.new(profile))
            end
            return res
          end,
        }
      ),
    },
    -- render = s:entry('basic', vx.callable, function(v)
    --   if type(v) == 'string' then
    --     local ok, preset = pcall(require('incline.presets').load, v)
    --     if ok then
    --       return preset
    --     end
    --   end
    --   return v
    -- end),
    -- debounce_threshold = s:entry(
    --   { rising = 10, falling = 50 },
    --   vx.any {
    --     vx.number.whole,
    --     vx.table.of_all { rising = vx.number.whole, falling = vx.number.whole },
    --   },
    --   function(v)
    --     if type(v) == 'number' then
    --       return { rising = v, falling = v }
    --     end
    --     return v
    --   end
    -- ),
    -- window = {
    --   width = s:entry('fit', vx.any { 'fit', 'fill', vx.number.natural, vx.number.percentage }),
    --   overlap = {
    --     winbar = s:entry(false, vx.bool),
    --     tabline = s:entry(false, vx.bool),
    --     borders = s:entry(true, vx.bool),
    --     statusline = s:entry(false, vx.bool),
    --   },
    --   placement = {
    --     vertical = s:entry('top', vx.any { 'top', 'bottom' }),
    --     horizontal = s:entry('right', vx.any { 'left', 'center', 'right' }),
    --   },
    --   margin = {
    --     horizontal = s:entry(
    --       1,
    --       vx.any {
    --         vx.number.whole,
    --         vx.table.of_all { left = vx.number.whole, right = vx.number.whole },
    --       },
    --       function(v)
    --         if type(v) == 'number' then
    --           return { left = v, right = v }
    --         end
    --         return v
    --       end
    --     ),
    --     vertical = s:entry(
    --       1,
    --       vx.any { vx.number.whole, vx.table.of_all { top = vx.number.whole, bottom = vx.number.whole } },
    --       function(v)
    --         if type(v) == 'number' then
    --           return { top = v, bottom = v }
    --         end
    --         return v
    --       end
    --     ),
    --   },
    --   padding = s:entry(
    --     1,
    --     vx.any {
    --       vx.number.whole,
    --       vx.table.of_all { left = vx.number.whole, right = vx.number.whole },
    --     },
    --     function(v)
    --       if type(v) == 'number' then
    --         return { left = v, right = v }
    --       end
    --       return v
    --     end
    --   ),
    --   padding_char = s:entry(' ', vx.string.length(1)),
    --   zindex = s:entry(50, vx.number.natural),
    --   winhighlight = s:entry(
    --     {
    --       active = {
    --         Search = 'None',
    --         EndOfBuffer = 'None',
    --         Normal = 'InclineNormal',
    --       },
    --       inactive = {
    --         Search = 'None',
    --         EndOfBuffer = 'None',
    --         Normal = 'InclineNormalNC',
    --       },
    --     },
    --     vx.table.of_all {
    --       active = vx.map(vx.string, vx.any { vx.highlight.any, vx.string }),
    --       inactive = vx.map(vx.string, vx.any { vx.highlight.any, vx.string }),
    --     },
    --     function(v, entry)
    --       if type(v) == 'table' then
    --         if not v.active and not v.inactive then
    --           v = { active = v, inactive = v }
    --         end
    --         v.active = tx.extend(v.active or {}, { default = entry.default.active })
    --         v.inactive = tx.extend(v.inactive or {}, { default = entry.default.inactive })
    --       end
    --       return v
    --     end
    --   ),
    --   options = s:entry({ wrap = false, signcolumn = 'no' }, vx.table, { transform = tx.extend }),
    -- },
    -- hide = {
    --   focused_win = s:entry(false, vx.bool),
    --   only_win = s:entry(false, vx.any { vx.bool, 'count_ignored' }),
    --   cursorline = s:entry(false, vx.any { vx.bool, 'focused_win' }),
    -- },
    -- ignore = {
    --   unlisted_buffers = s:entry(true, vx.bool),
    --   floating_wins = s:entry(true, vx.bool),
    --   filetypes = s:entry({}, vx.list.of(vx.string)),
    --   buftypes = s:entry(
    --     'special',
    --     vx.any {
    --       'special',
    --       vx.func,
    --       vx.list.of(vx.any {
    --         '',
    --         'acwrite',
    --         'help',
    --         'nofile',
    --         'nowrite',
    --         'quickfix',
    --         'terminal',
    --         'prompt',
    --       }),
    --     }
    --   ),
    --   wintypes = s:entry(
    --     'special',
    --     vx.any {
    --       'special',
    --       vx.func,
    --       vx.list.of(vx.any {
    --         '',
    --         'autocmd',
    --         'command',
    --         'loclist',
    --         'popup',
    --         'preview',
    --         'quickfix',
    --         'unknown',
    --       }),
    --     }
    --   ),
    -- },
    -- highlight = {
    --   groups = s:entry({
    --     InclineNormal = { group = 'NormalFloat', default = true },
    --     InclineNormalNC = { group = 'NormalFloat', default = true },
    --   }, vx.map(vx.string, vx.highlight.any), { transform = tx.extend }),
    -- },
  }, {
    deprecated = {
      fields = {},
      vals = {},
    },
  }
end)

---@type ConfigModule
local mt = setmetatable({
  setup = function(config)
    local schema, err = M.schema:parse(config, M.config)
    if err then
      local fmt_str = ({
        [Schema.result.INVALID_FIELD] = 'invalid field "%s"',
        [Schema.result.INVALID_VALUE] = 'invalid value for field "%s"',
        [Schema.result.INVALID_LEAF] = 'invalid value for field "%s": expected table',
        [Schema.result.DEPRECATED] = 'deprecated: %s',
      })[schema]
      local msg = fmt_str:format(err)
      vim.notify(('[blender.nvim] config error: %s'):format(msg), vim.log.levels.ERROR)
      return
    end
    M.config = schema
  end,

  reset = function()
    M.config = nil
  end,

  schema = M.schema,
}, {
  __index = function(_, k)
    if M[k] then
      return M[k]
    end
    if M.schema.transforms[k] then
      return M.schema.transforms[k]
    end
    if M.config == nil then
      M.config = M.schema:default()
    end
    if k == 'config' then
      return M.config
    end
    return M.config[k]
  end,
})

return mt
