<h1 align="center">Blender.nvim</h1>

<p align="center">
  <a href="https://github.com/b0o/blender.nvim/releases"><img alt="Version Badge" src="https://img.shields.io/github/v/tag/b0o/blender.nvim?style=flat&color=yellow&label=version&sort=semver"/></a>
  <a href="https://mit-license.org"><img alt="License: MIT" src="https://img.shields.io/github/license/b0o/blender.nvim?style=flat&color=green"/></a>
</p>

Develop Blender add-ons with Neovim. Blender.nvim streamlines the development process by providing a seamless integration between Blender and Neovim.

> [!NOTE]
> Blender.nvim is experimental and under active development.

## Features

- **Run your add-on directly from Neovim**
- **Refresh your add-on with a single Neovim command**
- **Reload your add-on automatically when a file changes**
- **Create profiles for different versions of Blender**
- **Debug your add-on with DAP**
- **Support for Python virtual environments**

## Installation

### Prerequisites

External Dependencies:

- [Neovim](https://neovim.io) >= 0.9.5
- [Blender](https://www.blender.org) >= 2.80
- [Python](https://www.python.org) >= 3.7

Neovim Plugin Dependencies:

- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- [nui-components.nvim](https://github.com/grapp-dev/nui-components.nvim)
- [nvim-dap (for DAP support, optional)](https://github.com/mfussenegger/nvim-dap)

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
    "mfussenegger/nvim-dap", -- optional
  },
}
```

## License & Credits

&copy; 2024 Maddison Hellstrom, [MIT License](https://mit-license.org).

Includes code from the following projects:

- [JacquesLucke/blender_vscode](https://github.com/JacquesLucke/blender_vscode)
  - The Python portion of Blender.nvim is a modified version of the code from blender_vscode.
  - The Lua portion of Blender.nvim is inspired by the TypeScript implementation of blender_vscode, but is not a copy.
  - License: MIT
- [stevearc/overseer.nvim](https://github.com/stevearc/overseer.nvim)
  - The jobstart terminal strategy is based on code from overseer.nvim.
  - License: MIT

Contributors:

- [b0o](https://github.com/b0o)
- [willothy](https://github.com/willothy)

Acknowledgements:

- [nui.nvim](https://github.com/MunifTanjim/nui.nvim): UI component library for Neovim
- [nui-components.nvim](https://github.com/grapp-dev/nui-components.nvim): UI framework built on top of nui.nvim
