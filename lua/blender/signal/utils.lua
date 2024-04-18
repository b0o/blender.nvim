local M = {}

---Returns `value` unchanged, but changes its LuaLS type to `SignalValue<T>`,
---so that it can be assigned to a signal value.
---@generic T
---@param value T
---@return SignalValue<T>
M.signal_value = function(value)
  return value
end

---Observes a SignalValue once and then unsubscribes.
---Note: You should use a fresh SignalValue, since any other Observers of the
---SignalValue will be unsubscribed as well.
---@generic T
---@param signal SignalValue<T>
---@param on_next fun(val: T): nil
---@return SignalValue<T>
M.observe_once = function(signal, on_next)
  local signal_value
  signal_value = signal:observe(function(value)
    vim.schedule(function()
      if not signal_value then
        return
      end
      signal_value:unsubscribe()
      on_next(value)
    end)
  end)
  return signal_value
end

return M
