require("catppuccin").setup {
  flavour = "mocha",
  transparent_background = true,
  float = {
    transparent = true,
    solid = true,
  },
  integrations = {
    cmp = true,
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
