return function()
  local execs = {
    ['Blender'] = 'blender',
    ['Blender 4.0'] = 'blender-4.0',
    ['Blender 4.1'] = 'blender-4.1',
    ['Blender 4.2'] = 'blender-4.2',
    ['Blender 4.3'] = 'blender-4.3',
    ['Blender 4.4'] = 'blender-4.4',
    ['Blender 4.5'] = 'blender-4.5',
  }

  local search_paths = {}
  if vim.fn.has 'unix' == 1 then
    table.insert(search_paths, '/bin')
    table.insert(search_paths, '/usr/bin')
    table.insert(search_paths, '/usr/local/bin')
  end
  if vim.fn.has 'mac' == 1 then
    execs['Blender.app'] = '/Applications/Blender.app/Contents/MacOS/Blender'
    table.insert(search_paths, '/opt/homebrew/bin')
  end
  local is_windows = vim.fn.has 'win32' == 1
  if is_windows then
    table.insert(search_paths, 'C:/Program Files/Blender Foundation')
  end

  ---@type ProfileParams[]
  local profiles = {}
  for name, exec in pairs(execs) do
    for _, path in ipairs {
      '',
      unpack(name:sub(1, 1) == '/' and {} or search_paths),
    } do
      local full_path = path == '' and exec or path .. '/' .. exec
      if is_windows then
        full_path = path .. '/' .. name .. '/blender'
      end
      local exec_path = vim.fn.exepath(full_path)
      if exec_path ~= '' then
        ---@type ProfileParams
        local profile = {
          name = name,
          cmd = exec_path,
        }
        table.insert(profiles, profile)
        break
      end
    end
  end

  return profiles
end
