require("catppuccin").setup {
  flavour = "mocha",
  transparent_background = true,
  float = {
    transparent = true,
    solid = true,
  },
  integrations = {
    telescope = { enabled = false },
    which_key = false,
    lsp_trouble = false,
    nvim_surround = false,
    notify = false,
    noice = false,
    indent_blankline = {
      enabled = false, -- Disabled since we use snacks.indent
    },
    mini = {
      enabled = true,
      indentscope_color = "lavender",
    },
    snacks = {
      enabled = true,
      indentscope_color = "lavender",
    },
  },
}

-- set colorscheme - setup must be called before loading
vim.cmd.colorscheme "catppuccin-nvim"

--- Completion popup menu: solid catppuccin 'surface0' bg so it doesn't inherit
--- the transparent_background setting. PmenuSel keeps its accent.
local palette = require("catppuccin.palettes").get_palette()
vim.api.nvim_set_hl(0, "Pmenu", { bg = palette.base, fg = palette.text })
vim.api.nvim_set_hl(0, "PmenuSbar", { bg = palette.base })
vim.api.nvim_set_hl(0, "PmenuThumb", { bg = palette.surface0 })
