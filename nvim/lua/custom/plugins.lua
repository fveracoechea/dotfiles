return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },
  {
    "neovim/nvim-lspconfig",
    config = function ()
      require "plugins.configs.lspconfig"
      require "custom.confgs.lspconfig"
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
      }
   }
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
        "yml",
        "dockerfile"
      },
    },
  },
}
