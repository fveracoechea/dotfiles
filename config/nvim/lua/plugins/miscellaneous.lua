require("todo-comments").setup()

require("herdr-nvim").setup {
  prefix = "<leader>h",
  clear_after_send = true,
}

require("ts_context_commentstring").setup {
  enable_autocmd = false,
}

require("nvim-ts-autotag").setup()

require("gitsigns").setup {
  current_line_blame = true,
}
