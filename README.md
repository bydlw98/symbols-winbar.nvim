# symbols-winbar.nvim

A lightweight VS Code like winbar plugin for displaying breadcrumbs.

## Features

- No dependency on nvim-navic
- No drop-down menus, only displays breadcrumbs
- Simple setup
- Uses VS Code Codicons by default

## Requirements

- [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) for file icons _(optional)_
- [Nerd Font](https://www.nerdfonts.com) with Codicons support

## Installation

### `vim.pack`

```lua
vim.pack.add({
  "https://github.com/bydlw98/symbols-winbar.nvim",

  ---Optional for file icons
  "https://github.com/nvim-tree/nvim-web-devicons"
})
require("symbols-winbar").setup()
```

### `lazy.nvim`

```lua
{
  "bydlw98/symbols-winbar.nvim",
  ---Optional for file icons
  dependencies = { "nvim-tree/nvim-web-devicons" }
  ---@module "symbols-winbar"
  ---@type symbols-winbar.Config
  opts = {}
}
```

## Configuration

Default options

```lua
require("symbols-winbar").setup({
  ---Checks if we should update the winbar of current window.
  ---@type fun():boolean
  is_enabled = function()
    return vim.bo.buftype == ""
  end,

  ---Icons for different `vim.lsp.protocol.SymbolKind`.
  ---@type table<string, string>
  kind_icons = {
    File = " ",
    Module = " ",
    Namespace = " ",
    Package = " ",
    Class = " ",
    Method = " ",
    Property = " ",
    Field = " ",
    Constructor = " ",
    Enum = " ",
    Interface = " ",
    Function = " ",
    Variable = " ",
    Constant = " ",
    String = " ",
    Number = " ",
    Boolean = " ",
    Array = " ",
    Object = " ",
    Key = " ",
    Null = " ",
    EnumMember = " ",
    Struct = " ",
    Event = " ",
    Operator = " ",
    TypeParameter = " ",
  },

  ---Padding string added to the start of winbar contents.
  ---@type string
  left_padding = "  ",

  ---Winbar content separator.
  ---@type string
  separator = "  ",

  ---Number of milliseconds before updating winbar.
  ---@type integer
  updatetime = 1500,
})
```

