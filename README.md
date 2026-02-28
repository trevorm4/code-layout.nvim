# code-layout.nvim

A neovim layout to show LSP symbols in a tree like structure, either in a split window or a floating window using [fzf-lua](https://github.com/ibhagwan/fzf-lua)

#### Sidebar
<img width="2526" height="1365" alt="Screenshot 2026-02-26 at 12 05 20 PM" src="https://github.com/user-attachments/assets/1878b7a4-9ee3-4344-865e-a8c846b3f364" />

#### Floating fuzzy finder (requires fzf-lua)
<img width="2283" height="1036" alt="Screenshot 2026-02-26 at 1 19 55 PM" src="https://github.com/user-attachments/assets/fb3aa7d2-d8c7-4d9f-93bb-403a8a316329" />



## 📦 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "trevorm4/code-layout.nvim",
  dependencies = {
    "ibhagwan/fzf-lua",           -- Optional: for fuzzy finding support
    "nvim-tree/nvim-web-devicons" -- Optional: for symbol icons
  },
  keys = {
    { "<leader>o", "<cmd>CodeLayoutRight<cr>", desc = "Open LSP symbol tree (sidebar)" },
    { "<leader>lf", "<cmd>CodeLayoutFloat<cr>", desc = "Open LSP symbol tree (fuzzy)" },
  },
  config = function()
    require('code_layout').setup({
      floating = {
        annotate = true, -- Set to false to hide the full symbol path in the fzf window
      },
    })
  end,
}
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'trevorm4/code-layout.nvim'
Plug 'ibhagwan/fzf-lua' " Optional for fuzzy finding
```

### Configuration

The plugin works out of the box without calling `setup()`. If you want to customize its behavior, you can call `setup()` with your preferred options.

The following are the default settings:

```lua
require('code_layout').setup({
  floating = {
    -- Whether to show the full symbol path (e.g., "Class › Method") in the fzf window.
    annotate = true,
  },
})
```

### Commands

| Command | Description |
| --- | --- |
| `:CodeLayoutRight` | Opens the LSP symbol tree in a vertical sidebar on the right. |
| `:CodeLayoutLeft` | Opens the LSP symbol tree in a vertical sidebar on the left. |
| `:CodeLayoutFloat` | Opens a floating fuzzy finder (powered by fzf-lua) for symbols. |

> [!NOTE]
> I have only personally used [lazy.nvim](https://github.com/folke/lazy.nvim), so please create an issue if it does not work with other plugin managers

### Navigation (Sidebar)

- **Move Cursor**: Use any native motion (`j`, `k`, `G`, etc.). The main buffer will automatically jump to the symbol under your cursor.
- **`<CR>` (Enter)**: Jump to the symbol and keep focus in the main window.
- **`q`**: Close the sidebar.

### Navigation (Fuzzy Finder)

- **Type to Filter**: Search by symbol name or parent context (e.g., search for "Config" to see all methods inside a Config class).
- **Preview**: See the code location in the preview pane as you scroll.
- **`<CR>` (Enter)**: Jump to the selected symbol.

## 🛠️ API (Advanced)

`code-layout.nvim` provides a chainable Lua API for creating custom window layouts:

```lua
local cl = require('code_layout').layout('float')

cl:left(20, 50, nil, "My Window")
  :setlines({"Hello World"})
  :bufopt('filetype', 'markdown')
  :done()
```

## Acknowledgements

- Heavily inspired by [lspsaga](https://github.com/nvimdev/lspsaga.nvim/), although it is no longer in development


## 📄 License

MIT
