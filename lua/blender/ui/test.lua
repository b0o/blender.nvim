local n = require 'nui-components'

local hl = require('blender.highlights').groups
local buffer = require 'blender.components.buffer'

return function()
  local renderer = n.create_renderer {
    width = 70,
    height = 40,
  }

  local buf = vim.api.nvim_create_buf(false, false)
  for _ = 1, 100 do
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, { 'Hello, world!' })
  end

  renderer:render(
    --
    n.rows(
      n.paragraph {
        is_focusable = false,
        lines = {
          n.line(n.text(' ', hl.BlenderAccent), n.text 'Test') or nil,
        },
      },
      buffer {
        buf = buf,
        size = 10,
        autofocus = true,
      }
    )
  )
end
