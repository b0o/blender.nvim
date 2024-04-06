local Schema = require 'blender.config.schema'
local vx = require 'blender.config.validate'
local tx = require 'blender.config.transform'

local M = {}

---@class BlenderConfig
---@field profiles List<ProfileParams>

---@class BlenderConfigResult : BlenderConfig

---@class DapConfig
---@field enabled boolean

---@class DapConfigResult : DapConfig

---@class NotifyConfig
---@field enabled boolean
---@field verbosity 'TRACE' | 'DEBUG' | 'INFO' | 'WARN' | 'ERROR' | 'OFF' | 0 | 1 | 2 | 3 | 4 | 5

---@class NotifyConfigResult : NotifyConfig
---@field verbosity 0 | 1 | 2 | 3 | 4 | 5

---@class Config
---@field blender BlenderConfig
---@field dap DapConfig
---@field notify NotifyConfig

---@class ConfigResult
---@field blender BlenderConfigResult
---@field dap DapConfigResult
---@field notify NotifyConfigResult

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
          enable_dap = vx.optional(vx.bool),
        }),
        { transform = tx.extend }
      ),
    },
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
      require('blender.util').notify('Config error: ' .. msg, 'ERROR')
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
