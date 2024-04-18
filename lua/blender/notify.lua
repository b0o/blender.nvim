local config = require 'blender.config'

---@param msg string
---@param level 'TRACE' | 'DEBUG' | 'INFO' | 'WARN' | 'ERROR' | 'OFF' | 0 | 1 | 2 | 3 | 4 | 5
return function(msg, level)
  local lvl = type(level) == 'string' and vim.log.levels[level] or level
  ---@cast lvl integer
  if config.notify.enabled and config.notify.verbosity <= lvl then
    vim.notify('[Blender.nvim] ' .. msg, lvl)
  end
end
