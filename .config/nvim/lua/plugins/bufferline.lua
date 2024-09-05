return {
  "akinsho/bufferline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  version = "*",
  config = function()
    local bufferline = require "bufferline"
    local catppucin_bufferline = require "catppuccin.groups.integrations.bufferline"

    bufferline.setup {
      options = {
        offsets = {
          {
            filetype = "Directory",
            text = " File Explorer ",
            highlight = "FileExplorer",
          },
        },
        highlights = catppucin_bufferline.get(),
      },
    }
  end,
}
