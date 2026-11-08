require "config.options"

-- Run `:lua vim.pack.update()` to update the tracked plugin lockfile.
vim.pack.add {
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/MunifTanjim/nui.nvim",
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  "https://github.com/JoosepAlviste/nvim-ts-context-commentstring",
  "https://github.com/windwp/nvim-ts-autotag",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/antosha417/nvim-lsp-file-operations",
  { src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
  "https://github.com/nvim-mini/mini.nvim",
  "https://github.com/folke/snacks.nvim",
  "https://github.com/folke/todo-comments.nvim",
  "https://github.com/akinsho/bufferline.nvim",
  "https://github.com/nvim-lualine/lualine.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/mistricky/codesnap.nvim",
  { src = "https://github.com/ChmaraX/herdr-nvim", version = "0450dc7b4c40c986052541c00dba5cdcd1be7ac6" },
}

require "config.keymaps"
require "config.autocmds"
require "config.lsp"

require "plugins.catppuccin"
require "plugins.miscellaneous"
require "plugins.mini"
require "plugins.bufferline"
require "plugins.snacks"
require "plugins.conform"
require "plugins.codesnap"
require "plugins.treesitter"
require "plugins.lualine"
