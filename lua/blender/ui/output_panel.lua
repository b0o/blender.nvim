local config = require 'blender.config'
local manager = require 'blender.manager'
local Panel = require 'blender.panel'

local instance

function OutputPanel()
  local task = manager.get_running_task()
  if instance then
    if task then
      local buf = task:get_buf()
      if buf and instance.buf ~= buf then
        instance:set_buf(buf)
      end
    end
    return instance
  end
  if not task then
    return
  end
  local buf = task:get_buf()
  if not buf then
    return
  end
  local height = config.ui.output_panel.height
  if height > 0 and height < 1 then
    height = math.floor(vim.o.lines * height)
  end
  local panel = Panel.create_panel {
    buf = buf,
    height = height,
  }
  instance = panel
  return panel
end

return OutputPanel
