return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    local catppuccin = require "catppuccin"

    catppuccin.setup {
      flavour = "mocha",
      transparent_background = false,
      integrations = {
        which_key = true,
        lsp_trouble = true,
        nvim_surround = true,
        indent_blankline = {
          enabled = true,
          scope_color = "lavender", -- catppuccin color (eg. `lavender`) Default: text
          colored_indent_levels = true,
        },
      },
    }

    vim.cmd.colorscheme "catppuccin"
  end,
}
