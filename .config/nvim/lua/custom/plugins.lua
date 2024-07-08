local plugins = {
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
    "nvimtools/none-ls.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvimtools/none-ls-extras.nvim",
    },
    opts = function()
      return require "custom.configs.none-ls"
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
        "eslint_d",
        "graphql-language-service-cli",
        "html-lsp",
        "prettierd",
        "tailwindcss-language-server",
        "typescript-language-server",
        "deno",
        "css-lsp",
        "json-lsp",
        "codespell",
        "nginx-language-server",
        "editorconfig-checker",
        -- "black",
        -- "isort",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    event = "VeryLazy",
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "windwp/nvim-ts-autotag",
    },
    opts = {
      -- enable autotagging with nvim-ts-autotag
      autotag = { enable = true },
      -- enable incrementa selection
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<leader>cs",
          node_incremental = "<leader>cs",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
      -- ensure these language parsers are installed
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
        "markdown_inline",
        "make",
        "yaml",
        "dockerfile",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    lazy = true,
    config = function()
      require "custom.configs.text-objects"
    end,
  },
}

-- enable mdx
vim.filetype.add {
  extension = {
    mdx = "markdown",
    nginx = "conf.tmpl",
  },
}

local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

parser_config.nginx = {
  install_info = {
    url = "https://gitlab.com/joncoole/tree-sitter-nginx",
    branch = "main",
    files = { "src/parser.c" },
  },
}

return plugins
