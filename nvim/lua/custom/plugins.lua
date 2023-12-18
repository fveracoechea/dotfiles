return {
  {
    "barrett-ruth/import-cost.nvim",
    event = "VeryLazy",
    build = "sh install.sh npm",
    config = true,
  },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },
  {
    "stevearc/conform.nvim",
    event = "VeryLazy",
    config = function()
      require "custom.configs.formatter"
    end,
  },
  {
    "mfussenegger/nvim-lint",
    event = "VeryLazy",
    config = function()
      require "custom.configs.linter"
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "stylua",
        "eslint-lsp",
        "graphql-language-service-cli",
        "html-lsp",
        "prettier",
        "tailwindcss-language-server",
        "typescript-language-server",
        "css-lsp",
        "black",
        "isort",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        -- defaults
        "vim",
        "lua",
        "gitignore",
        "gitattributes",

        -- web dev
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",
        "json",
        "graphql",
        -- text files
        "markdown",
        "make",
        -- "yml",
        "dockerfile",
      },
    },
  },
}
