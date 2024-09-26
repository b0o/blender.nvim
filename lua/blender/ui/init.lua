local state = {
  instance = nil,
}

---@class Blender.Ui
local M = {}

M._on_open = function(instance)
  M.close()
  state.instance = instance
end

M._on_close = function()
  state.instance = nil
end

M.is_open = function()
  return state.instance ~= nil
end

M.close = function()
  if state.instance then
    state.instance.close()
    state.instance = nil
  end
end

return M
