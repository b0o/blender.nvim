<h1 align="center">Blender.nvim</h1>

**Develop Blender add-ons with Neovim.**

Blender.nvim streamlines the add-on development process by launching Blender
directly from Neovim and automatically installing your add-on. Then, after
you've made some changes to your code and want to reload your add-on, a single
command will refresh it without needing to restart Blender.

> [!NOTE]
> Blender.nvim is experimental and under active development.

## Features

- **Run your add-on directly from Neovim**
- **Refresh your add-on with a single Neovim command**
- **Reload your add-on automatically when a file changes**
- **Create profiles for different versions of Blender**
- **Debug your add-on with DAP**
- **Support for Python virtual environments**

https://github.com/b0o/blender.nvim/assets/21299126/961f4bb9-4924-4bee-8540-d8392036c482

https://github.com/b0o/blender.nvim/assets/21299126/cce964de-7cb6-4dfb-86d4-2cf2978b36f3

## Installation

### Prerequisites

External Dependencies:

- [Neovim](https://neovim.io) >= 0.9.5
- [Blender](https://www.blender.org) >= 2.80
- [Python](https://www.python.org) >= 3.7

Neovim Plugin Dependencies:

- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- [nui-components.nvim](https://github.com/grapp-dev/nui-components.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [nvim-dap (for DAP support, optional)](https://github.com/mfussenegger/nvim-dap)
- [nvim-dap-repl-highlights (for syntax highlighting in the DAP REPL, optional)](https://github.com/LiadOz/nvim-dap-repl-highlights)

Lazy.nvim:

```lua
use {
  "b0o/blender.nvim",
  config = function()
    require("blender").setup()
  end,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "grapp-dev/nui-components.nvim",
    'nvim-lua/plenary.nvim',
    "mfussenegger/nvim-dap", -- optional
    "LiadOz/nvim-dap-repl-highlights", -- optional, for syntax highlighting in the DAP REPL
  },
}
```

## Configuration

Default configuration:

```lua
require("blender").setup {
  profiles = { --               Profile[]?      list of blender profiles
    --
    {
      name = 'blender', --      string           profile name, must be unique
      cmd = 'blender', --       string|string[]  command to run Blender
      -- use_launcher = true -- boolean?         whether to run the launch_blender.py script when starting Blender
      -- extra_args = {} --     string[]?        extra arguments to pass to Blender
      -- enable_dap = nil --    boolean?         whether to enable DAP for this profile (if nil, the global setting is used)
      -- watch = nil --         boolean?         whether to watch the add-on directory for changes (if nil, the global setting is used)
    },
  },
  dap = { --                     DapConfig?       DAP configuration
    enabled = true, --           boolean?         whether to enable DAP (can be overridden per profile)
  },
  notify = { --                  NotifyConfig?    notification configuration
    enabled = true, --           boolean?         whether to enable notifications
    verbosity = 'INFO', --       'TRACE'|'DEBUG'|'INFO'|'WARN'|'ERROR'|'OFF'|vim.log.level?  log level for notifications
  },
  watch = { --                   WatchConfig?     file watcher configuration
    enabled = true, --           boolean?         whether to watch the add-on directory for changes (can be overridden per profile)
  },
}
```

The `setup()` function can be called multiple times, and the configuration will be merged.

This comes in handy for using `.nvim.lua` ([`:help exrc`](https://neovim.io/doc/user/options.html#'exrc')) files to configure Blender.nvim on a per-project basis. For example:

```lua
--- ~/projects/my-blender-addon/.nvim.lua
local has_blender, blender = pcall(require, "blender")
if has_blender then
  blender.setup({
    profiles = {
      {
        name = "my_addon",
        cmd = "blender",
        -- Open a specific file when launching Blender:
        extra_args = { vim.env.HOME .. "/blender-files/my-test-file.blend" },
      },
    },
  })
end
```

For this to work, you need to ensure you have `:set exrc` in your Neovim configuration. Then, restart Neovim and, when prompted, allow the `.nvim.lua` file to be loaded.

## Usage

### Commands

- `:BlenderLaunch` - Launch a Blender profile
- `:BlenderManage` - Manage a running Blender task
- `:BlenderReload` - Reload the Blender add-on
- `:BlenderWatch` - Watch for changes and reload the add-on
- `:BlenderUnwatch` - Stop watching for changes

### Lua API

```lua
local actions = require("blender.actions")

---Launch a Blender profile
actions.show_launcher()

---Manage a running Blender task
actions.show_task_manager()

---Reload the Blender add-on
actions.reload()

---Start watching for changes in the addon files
---Note: When the task exits, the watch is removed.
---@param patterns? string|string[] # pattern(s) matching files to watch for changes
actions.watch(patterns)

---Stop watching for changes in the addon files
actions.unwatch()
```

## License & Credits

Includes code from the following projects:

- [JacquesLucke/blender_vscode](https://github.com/JacquesLucke/blender_vscode)
  - The Python portion of Blender.nvim is a modified version of the code from blender_vscode.
  - The Lua portion of Blender.nvim is inspired by the TypeScript implementation of blender_vscode, but is not a copy.
  - License: MIT
- [stevearc/overseer.nvim](https://github.com/stevearc/overseer.nvim)
  - The jobstart terminal strategy is based on code from overseer.nvim.
  - License: MIT

### Contributors

- [b0o](https://github.com/b0o)
- [willothy](https://github.com/willothy)

### Acknowledgements

- [nui.nvim](https://github.com/MunifTanjim/nui.nvim): UI component library for Neovim
- [nui-components.nvim](https://github.com/grapp-dev/nui-components.nvim): UI framework built on top of nui.nvim

### License

&copy; 2024 Maddison Hellstrom, [MIT License](https://mit-license.org).

Blender is a registered trademark (®) of the Blender Foundation in EU and USA. This project is not affiliated with or endorsed by the Blender Foundation.
