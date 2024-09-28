local M = {}

---@class ConfigParams : Config

---@param config ConfigParams
M.setup = function(config)
  require('blender.config').setup(config or {})
  require('blender.highlights').setup()
  require('blender.commands').setup()
end

return M
