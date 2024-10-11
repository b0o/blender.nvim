local Schema = require 'blender.config.schema'
local vx = require 'blender.config.validate'
local tx = require 'blender.config.transform'
local detect_profiles = require 'blender.profile.detect'

local M = {}

---@class DapConfig
---@field enabled boolean

---@class DapConfigResult : DapConfig

---@class NotifyConfig
---@field enabled boolean
---@field verbosity 'TRACE' | 'DEBUG' | 'INFO' | 'WARN' | 'ERROR' | 'OFF' | 0 | 1 | 2 | 3 | 4 | 5

---@class NotifyConfigResult : NotifyConfig
---@field verbosity 0 | 1 | 2 | 3 | 4 | 5

---@class WatchConfig
---@field enabled boolean

---@class WatchConfigResult : WatchConfig

---@class UiConfig
---@field output_panel { height: number }

---@class UiConfigResult : UiConfig

---@alias ProfileGenerator fun(): ProfileParams|ProfileParams[]

---@class Config
---@field profiles (ProfileParams|ProfileGenerator)[]|ProfileGenerator
---@field dap DapConfig
---@field notify NotifyConfig
---@field watch WatchConfig
---@field ui UiConfig

---@class ConfigResult
---@field profiles ProfileParams[]
---@field dap DapConfigResult
---@field notify NotifyConfigResult
---@field watch WatchConfigResult
---@field ui UiConfigResult

---@class ConfigModule : ConfigResult
---@field setup fun(config: Config)
---@field reset fun()
---@field schema table

M.schema = Schema(function(s)
  return {
    profiles = s:entry(
      detect_profiles(),
      vx.any {
        vx.list.of(vx.any {
          vx.table.of_all {
            name = vx.string,
            cmd = vx.any { vx.string, vx.list.of(vx.string) },
            env = vx.optional(vx.map(vx.string, vx.string)),
            use_launcher = vx.optional(vx.bool),
            extra_args = vx.optional(vx.list.of(vx.string)),
            enable_dap = vx.optional(vx.bool),
            watch = vx.optional(vx.bool),
          },
          vx.callable,
        }),
        vx.callable,
      },
      {
        transform = function(val, entry)
          if type(val) == 'function' then
            val = { val }
          end
          return tx.prepend(val, entry)
        end,
      }
    ),
    dap = {
      enabled = s:entry(true, vx.bool),
    },
    notify = {
      enabled = s:entry(true, vx.bool),
      verbosity = s:entry(
        vim.log.levels.INFO,
        vx.any { 'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'OFF', 0, 1, 2, 3, 4, 5 },
        {
          transform = function(v)
            if type(v) == 'string' and vim.log.levels[v] then
              return vim.log.levels[v]
            end
            return v
          end,
        }
      ),
    },
    watch = {
      enabled = s:entry(true, vx.bool),
    },
    ui = {
      output_panel = {
        height = s:entry(0.25, vx.number.positive),
      },
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
      vim.notify('[Blender.nvim] ' .. fmt_str:format(err), vim.log.levels.ERROR)
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
