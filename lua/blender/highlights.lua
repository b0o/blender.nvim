local M = {}

local a = vim.api

M.groups = {
  BlenderAccent = 'BlenderAccent',
  BlenderSelectOptionSelected = 'BlenderSelectOptionSelected',
  BlenderSelectOptionFocused = 'BlenderSelectOptionFocused',

  NuiComponentsSelectOption = 'NuiComponentsSelectOption',
  NuiComponentsSelectOptionSelected = 'NuiComponentsSelectOptionSelected',
  NuiComponentsSelectSeparator = 'NuiComponentsSelectSeparator',
  NuiComponentsSelectNodeFocused = 'NuiComponentsSelectNodeFocused',

  NuiComponentsButton = 'NuiComponentsButton',
  NuiComponentsButtonActive = 'NuiComponentsButtonActive',
  NuiComponentsButtonFocused = 'NuiComponentsButtonFocused',
}

M.palette = {
  accent = '#fe9e39',
  white = '#ffffff',
  black = '#000000',
}

local g = M.groups
local p = M.palette

M.highlights = {
  [g.BlenderAccent] = { fg = p.accent },
  [g.BlenderSelectOptionSelected] = { link = 'Visual' },
  [g.BlenderSelectOptionFocused] = { link = 'CursorLine' },

  [g.NuiComponentsSelectOption] = { link = 'Normal' },
  [g.NuiComponentsSelectOptionSelected] = { link = 'Visual' },
  [g.NuiComponentsSelectSeparator] = { link = 'Comment' },
  [g.NuiComponentsSelectNodeFocused] = { link = 'CursorLine' },

  [g.NuiComponentsButton] = { link = 'Normal' },
  [g.NuiComponentsButtonFocused] = { link = 'Visual' },
  [g.NuiComponentsButtonActive] = { fg = p.accent, bg = vim.api.nvim_get_hl(0, { name = 'CursorLine' }).bg },
}

M.setup = function()
  for group, hl in pairs(M.highlights) do
    a.nvim_set_hl(0, group, vim.tbl_extend('force', { default = true }, hl))
  end
end

return M
