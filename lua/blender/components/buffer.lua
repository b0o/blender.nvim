local Component = require 'nui-components.component'
local buf_storage = require 'nui.utils.buf_storage'

local fn = require 'nui-components.utils.fn'

local Buffer = Component:extend 'Buffer'

function Buffer:init(props, popup_options)
  Buffer.super.init(
    self,
    fn.merge({
      buf = nil,
      autoscroll = false,
    }, props),
    fn.deep_merge({
      buf_options = {
        filetype = props.filetype or '',
      },
    }, popup_options)
  )
end

function Buffer:prop_types()
  return {
    buf = 'number',
    autoscroll = 'boolean',
  }
end

function Buffer:_buf_create()
  local props = self:get_props()
  self.bufnr = props.buf
  if props.autoscroll then
    self._autoscroll_id = vim.api.nvim_create_autocmd('TextChanged', {
      buffer = self.bufnr,
      callback = function()
        if not self.winid or not vim.api.nvim_win_is_valid(self.winid) then
          return
        end
        if not self.bufnr or not vim.api.nvim_buf_is_valid(self.bufnr) then
          return true -- Remove autocmd
        end
        vim.api.nvim_win_set_cursor(self.winid, {
          vim.api.nvim_buf_line_count(self.bufnr),
          9999, -- Large number
        })
      end,
    })
  end
end

-- Note: Don't delete the buffer, we don't own it
function Buffer:_buf_destroy()
  buf_storage.cleanup(self.bufnr)
  if self._autoscroll_id then
    vim.api.nvim_del_autocmd(self._autoscroll_id)
    self._autoscroll_id = nil
  end
  self.bufnr = nil
end

function Buffer:on_update()
  local props = self:get_props()
  if props.buf and self.bufnr ~= props.buf and self._.layout_ready then
    local is_focused = vim.api.nvim_get_current_win() == self.winid
    self:unmount()
    self:mount()
    if is_focused then
      vim.api.nvim_set_current_win(self.winid)
    end
  end
end

return Buffer
