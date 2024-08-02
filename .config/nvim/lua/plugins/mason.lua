return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  config = function()
    local mason = require "mason"
    local mason_lspconfig = require "mason-lspconfig"
    local mason_tool_installer = require "mason-tool-installer"

    -- enable mason and configure icons
    mason.setup {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    }

    mason_lspconfig.setup {
      -- list of servers for mason to install
      ensure_installed = {
        "tsserver",
        "html",
        "cssls",
        "tailwindcss",
        "lua_ls",
        "graphql",
        "emmet_ls",
        "pyright",
        "denols",
        "nginx_language_server",
        "bashls",
        "jsonls",
      },
    }

    mason_tool_installer.setup {
      ensure_installed = {
        "prettier", -- prettier formatter
        "stylua", -- lua formatter
        "isort", -- python formatter
        "black", -- python formatter
        "pylint",
        "eslint_d",
      },
    }
  end,
  -- opts = {
  --   ensure_installed = {
  --     "lua-language-server",
  --     "stylua",
  --     "eslint-lsp",
  --     "eslint_d",
  --     "graphql-language-service-cli",
  --     "html-lsp",
  --     "prettierd",
  --     "tailwindcss-language-server",
  --     "typescript-language-server",
  --     "deno",
  --     "css-lsp",
  --     "json-lsp",
  --     "codespell",
  --     "nginx-language-server",
  --     "editorconfig-checker",
  --     "bash-language-server",
  --     "shfmt",
  --   },
  -- },
}
