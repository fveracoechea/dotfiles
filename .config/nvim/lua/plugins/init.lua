local plugins = {
  {
    "barrett-ruth/import-cost.nvim",
    event = "VeryLazy",
    build = "sh install.sh npm",
    config = true,
  },
  {
    "lewis6991/hover.nvim",
    config = function()
      local hover = require "hover"
      hover.setup {
        init = function()
          -- Require providers
          require "hover.providers.lsp"
          -- require "hover.providers.gh"
          -- require "hover.providers.gh_user"
          -- require('hover.providers.jira')
          -- require('hover.providers.dap')
          -- require('hover.providers.fold_preview')
          require "hover.providers.diagnostic"
          -- require "hover.providers.man"
          -- require "hover.providers.dictionary"
        end,
        preview_opts = {
          border = "single",
        },
        -- Whether the contents of a currently open hover window should be moved
        -- to a :h preview-window when pressing the hover keymap.
        preview_window = false,
        title = true,
        mouse_providers = {
          "LSP",
        },
        mouse_delay = 1000,
      }
    end,
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
      return require "configs.none-ls"
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
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
