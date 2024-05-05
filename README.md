<h1 align="center">🔶 Blender.nvim</h1>

**Develop Blender add-ons with Neovim.**

> [!NOTE]
> Blender.nvim is experimental and under active development.

## Features

- **Run** your add-on in Blender directly from Neovim
- **Refresh** your add-on with a single Neovim command
- **Watch** your add-on directory for changes and automatically reload
- **Project-specific** configuration with profiles and `.nvim.lua` files
- **Debug** your add-on with [DAP](https://microsoft.github.io/debug-adapter-protocol/)

https://github.com/b0o/blender.nvim/assets/21299126/961f4bb9-4924-4bee-8540-d8392036c482

https://github.com/b0o/blender.nvim/assets/21299126/cce964de-7cb6-4dfb-86d4-2cf2978b36f3

## Installation

### Prerequisites

Blender.nvim requires a recent version of Neovim and Blender. The following versions are known to work:

- [Neovim](https://neovim.io) >= 0.10.0 (nightly)
- [Blender](https://www.blender.org) >= 4.1.0

#### Neovim Plugin Dependencies:

- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- [nui-components.nvim](https://github.com/grapp-dev/nui-components.nvim)
- [nvim-dap](https://github.com/mfussenegger/nvim-dap) (Optional, for debugging with DAP)
- [nvim-dap-repl-highlights](https://github.com/LiadOz/nvim-dap-repl-highlights) (Optional, for syntax highlighting in the DAP REPL)

#### Python Dependencies:

It's recommended to use a Python virtual environment for Blender.nvim. Install the following packages in your virtual environment:

- [pynvim](https://github.com/neovim/pynvim)
- [debugpy](https://github.com/microsoft/debugpy) (Optional, for DAP support)

Activate your virtual environment and launch Neovim from within it to ensure the Python dependencies are available.

For an example starter project, see [blender-addon-template](https://github.com/b0o/blender-addon-template).

### Lazy.nvim

```lua
use {
  "b0o/blender.nvim",
  config = function()
    require("blender").setup()
  end,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "grapp-dev/nui-components.nvim",
    "mfussenegger/nvim-dap", -- Optional, for debugging with DAP
    "LiadOz/nvim-dap-repl-highlights", -- Optional, for syntax highlighting in the DAP REPL
  },
}
```

## Configuration

Default configuration:

```lua
require("blender").setup {
  profiles = { --                 Profile[]?       list of blender profiles
    --
    {
      name = 'blender', --        string           profile name, must be unique
      cmd = 'blender', --         string|string[]  command to run Blender
      -- use_launcher = true --   boolean?         whether to run the launcher.py script when starting Blender
      -- extra_args = {} --       string[]?        extra arguments to pass to Blender
      -- enable_dap = nil --      boolean?         whether to enable DAP for this profile (if nil, the global setting is used)
      -- watch = nil --           boolean?         whether to watch the add-on directory for changes (if nil, the global setting is used)
    },
  },
  dap = { --                      DapConfig?       DAP configuration
    enabled = true, --            boolean?         whether to enable DAP (can be overridden per profile)
  },
  notify = { --                   NotifyConfig?    notification configuration
    enabled = true, --            boolean?         whether to enable notifications
    verbosity = 'INFO', --        'TRACE'|'DEBUG'|'INFO'|'WARN'|'ERROR'|'OFF'|vim.log.level?  log level for notifications
  },
  watch = { --                    WatchConfig?     file watcher configuration
    enabled = true, --            boolean?         whether to watch the add-on directory for changes (can be overridden per profile)
  },
}
```

### Per-Project Configuration

You can use `.nvim.lua` ([`:help exrc`](https://neovim.io/doc/user/options.html#'exrc')) files to configure Blender.nvim on a per-project basis.

To enable support for `.nvim.lua` files in Neovim, you need to have `:set exrc` or `vim.o.exrc = true` in your Neovim configuration. Then, restart Neovim and, when prompted, allow the `.nvim.lua` file to be loaded.

Blender.nvim's `setup()` function can be called multiple times. Each call will merge the new configuration with the existing configuration.
For example, to add a profile for a Blender add-on in a specific project, you can create a `.nvim.lua` file in the project directory:

```lua
--- ~/projects/my-blender-addon/.nvim.lua
local has_blender, blender = pcall(require, "blender")
if has_blender then
  blender.setup {
    profiles = {
      {
        name = "my_addon",
        cmd = "blender",
        -- Open a specific file when launching Blender:
        extra_args = { vim.env.HOME .. "/blender-files/my-test-file.blend" },
      },
    },
  }
end
```


## Usage

### Commands

- `:Blender` - Open the Blender.nvim UI
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

- [JacquesLucke/blender_vscode](https://github.com/JacquesLucke/blender_vscode) (MIT License)
  - The Python portion of Blender.nvim is a heavily modified version of the code from blender_vscode.
  - The Lua portion of Blender.nvim is inspired by the TypeScript implementation of blender_vscode, but is not a copy.
- [stevearc/overseer.nvim](https://github.com/stevearc/overseer.nvim) (MIT License)
  - The jobstart terminal strategy is based on code from overseer.nvim.

### Acknowledgements

- [nui.nvim](https://github.com/MunifTanjim/nui.nvim): UI component library for Neovim
- [nui-components.nvim](https://github.com/grapp-dev/nui-components.nvim): UI framework built on top of nui.nvim
- [willothy](https://github.com/willothy) for the original Buffer component implementation

### License

&copy; 2024 Maddison Hellstrom, [MIT License](https://mit-license.org).

Blender is a registered trademark (®) of the Blender Foundation in EU and USA. This project is not affiliated with or endorsed by the Blender Foundation.
