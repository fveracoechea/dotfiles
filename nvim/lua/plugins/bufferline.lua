return {
  "akinsho/bufferline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  enabled = false,
  version = "*",
  config = function()
    local bufferline = require "bufferline"
    local catppucin_bufferline = require "catppuccin.groups.integrations.bufferline"
    local mocha = require("catppuccin.palettes").get_palette "mocha"

    bufferline.setup {
      options = {
        mode = "tabs",
        -- separator_style = "slant",
        offsets = {
          {
            filetype = "NvimTree",
            text = " ",
            highlight = "FileExplorer",
          },
        },
        highlights = catppucin_bufferline.get(),
      },
    }
  end,
}
