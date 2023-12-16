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
        "eslint-lsp",
        "graphql-language-service-cli",
        "html-lsp",
        "prettier",
        "tailwindcss-language-server",
        "typescript-language-server",
        "css-lsp",
      }
    }
  }
}
