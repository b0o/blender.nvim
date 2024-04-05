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
