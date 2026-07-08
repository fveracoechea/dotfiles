require("nvim-treesitter").setup {
  ensure_installed = {},
  auto_install = false,
  highlight = { enable = true },
  indent = { enable = true },
  autotag = { enable = true },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<C-space>",
      node_incremental = "<C-space>",
      scope_incremental = false,
      node_decremental = "<bs>",
    },
  },
}
