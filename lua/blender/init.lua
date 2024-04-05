local M = {}

---@param config Config
M.setup = function(config)
  require('blender.config').setup(config or {})
  require('blender.highlights').setup()
  require('blender.commands').setup()
end

return M
