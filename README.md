<h1 align="center">🔶 Blender.nvim</h1>

**Develop Blender add-ons with Neovim.**

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

- [Neovim](https://neovim.io) >= 0.11.0 (nightly)
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

If you're managing your virtualenv with [Rye](https://rye.astral.sh/), see the [note below](#rye-virtual-environment-support).

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
  profiles = { --                 Profile[]?            list of blender profiles
    --
    {
      name = 'blender', --        string                profile name, must be unique
      cmd = 'blender', --         string|string[]       command to run Blender
      -- env = {}, --             { [string]: string }  environment variables to set when starting Blender
      -- use_launcher = true --   boolean?              whether to run the launcher.py script when starting Blender
      -- extra_args = {} --       string[]?             extra arguments to pass to Blender
      -- enable_dap = nil --      boolean?              whether to enable DAP for this profile (if nil, the global setting is used)
      -- watch = nil --           boolean?              whether to watch the add-on directory for changes (if nil, the global setting is used)
    },
  },
  dap = { --                      DapConfig?            DAP configuration
    enabled = true, --            boolean?              whether to enable DAP (can be overridden per profile)
  },
  notify = { --                   NotifyConfig?         notification configuration
    enabled = true, --            boolean?              whether to enable notifications
    verbosity = 'INFO', --        'TRACE'|'DEBUG'|'INFO'|'WARN'|'ERROR'|'OFF'|vim.log.level?  log level for notifications
  },
  watch = { --                    WatchConfig?          file watcher configuration
    enabled = true, --            boolean?              whether to watch the add-on directory for changes (can be overridden per profile)
  },
}
```

### Custom Profiles

You can define custom profiles to launch Blender with different configurations.
A profile is a table with the following fields:

- `name`: The name of the profile
- `cmd`: The command to run Blender
- `env`: Environment variables to set when launching Blender (optional)
- `use_launcher`: Whether to run the launcher.py script when starting Blender (optional)
- `extra_args`: Extra arguments to pass to Blender (optional)
- `enable_dap`: Whether to enable DAP for this profile (optional)
- `watch`: Whether to watch for changes and reload the addon (optional)

You can also use a function to generate profiles dynamically.
For example, the following dynamically populates the `env` field of a profile:

```lua
blender.setup({
  profiles = function()
    local env = {}
    local ok, lines = pcall(vim.fn.readfile, "myproject.env")
    if not ok then
      -- Don't generate a profile if the file doesn't exist
      return
    end
    if ok and lines then
      -- Read a key=value pair from each line of the file, and add it to the env table
      for _, line in ipairs(lines) do
        local key, value = line:match("^([^#]*)=(.*)$")
        if key and value then
          env[key] = value
        end
      end
    end
    return {
      name = "myproject",
      cmd = "blender",
      env = env,
    }
  end,
})
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
- `:BlenderOutput` - Toggle the output panel

### Lua API

```lua
local actions = require("blender.actions")

---Open the Blender.nvim UI
---If no task is running, the launcher is shown,
---otherwise the task manager is shown.
actions.show_ui()

---Close the Blender.nvim UI
actions.close_ui()

---Toggle the Blender.nvim UI
actions.toggle_ui()

---Show the Blender.nvim task launcher
actions.show_launcher()

---Manage a running Blender task
actions.show_task_manager()

---Open the output panel
actions.show_output_panel()

---Close the output panel
actions.close_output_panel()

---Toggle the output panel
actions.toggle_output_panel()

---Reload the Blender add-on
actions.reload()

---Start watching for changes in the addon files
---Note: When the task exits, the watch is removed.
---@param patterns? string|string[] # pattern(s) matching files to watch for changes
actions.watch(patterns)

---Stop watching for changes in the addon files
actions.unwatch()
```

### Rye Virtual Environment Support

[Rye](https://rye.astral.sh/) is a project and package management solution for Python. It can create virtual environments, manage dependencies, and more.

Rye downloads and manages its own Python installations rather than using your system Python installation.
Because of this, you may experience errors when launching Blender from within a Rye virtual environment, because Blender expects to use the system Python installation.

To fix this, you can register the Python installation used by Blender as a Rye toolchain:

```sh
$ rye toolchain register -n blender-cpython /usr/bin/python3.12 # replace with your Blender Python executable
```

To determine the path to your Blender Python executable, launch Blender with the following command (make sure you're not in a Python virtual environment):

```sh
$ blender --background --python-expr "import sys; print(sys.executable)"
```

After you've registered the toolchain, create a `.python-version` file in your Blender Add-on project directory:

```conf
# replace with your Rye toolchain name/version:
blender-cpython@3.12
```

Then, run `rye sync` to update the Rye `.venv`. After this, you should be able to use Blender.nvim from within the Rye virtual environment.

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
