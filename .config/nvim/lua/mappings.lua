require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

map("n", "<C-h>", "<cmd> TmuxNavigateLeft<CR>", { desc = "window left" })
map("n", "<C-l>", "<cmd> TmuxNavigateRight<CR>", { desc = "window right" })
map("n", "<C-j>", "<cmd> TmuxNavigateDown<CR>", { desc = "window down" })
map("n", "<C-k>", "<cmd> TmuxNavigateUp<CR>", { desc = "window up" })

-- hover keymaps
map("n", "K", require("hover").hover, { desc = "hover.nvim" })
map("n", "gK", require("hover").hover_select, { desc = "hover.nvim (select)" })
map("n", "<C-p>", function()
  require("hover").hover_switch "previous"
end, { desc = "hover.nvim (previous source)" })
map("n", "<C-n>", function()
  require("hover").hover_switch "next"
end, { desc = "hover.nvim (next source)" })

-- Hover Mouse support
map("n", "<MouseMove>", require("hover").hover_mouse, { desc = "hover.nvim (mouse)" })
vim.o.mousemoveevent = true
