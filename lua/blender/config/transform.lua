local M = {}

M.append = function(val, entry)
  if val == nil then
    return entry.default
  end
  if type(val) ~= 'table' then
    return val
  end
  if vim.islist(entry.default) and vim.islist(val) then
    local res = vim.deepcopy(entry.default)
    vim.list_extend(res, val)
    return res
  else
    return vim.tbl_extend('force', entry.default, val)
  end
end

M.prepend = function(val, entry)
  if val == nil then
    return entry.default
  end
  if type(val) ~= 'table' then
    return val
  end
  if vim.islist(entry.default) and vim.islist(val) then
    local res = vim.deepcopy(val)
    vim.list_extend(res, entry.default)
    return res
  else
    return vim.tbl_extend('force', val, entry.default)
  end
end

M.replace = function(val, entry)
  return val ~= nil and val or entry.default
end

M.reset = function(_, entry)
  return entry.default
end

return M
