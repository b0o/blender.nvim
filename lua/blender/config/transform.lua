local M = {}

M.extend = function(val, entry)
  if val == nil then
    return entry.default
  end
  if type(val) ~= 'table' then
    return val
  end
  if vim.tbl_islist(entry.default) and vim.tbl_islist(val) then
    local res = vim.deepcopy(entry.default)
    vim.list_extend(res, val)
    return res
  else
    return vim.tbl_extend('force', entry.default, val)
  end
end

M.replace = function(val, entry)
  return val ~= nil and val or entry.default
end

M.reset = function(_, entry)
  return entry.default
end

return M
