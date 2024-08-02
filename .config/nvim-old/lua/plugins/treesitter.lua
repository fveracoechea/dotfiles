-- Register nginx paerser
local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.nginx = {
  install_info = {
    url = "https://gitlab.com/joncoole/tree-sitter-nginx",
    branch = "main",
    files = { "src/parser.c" },
  },
}

-- Enable mdx
vim.filetype.add {
  extension = {
    mdx = "markdown",
  },
}

---@type NvPluginSpec
return {
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
}
