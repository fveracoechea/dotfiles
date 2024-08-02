require "nvchad.mappings"
local hover = require "hover"

local map = vim.keymap.set

map("n", "<C-h>", "<cmd> TmuxNavigateLeft<CR>", { desc = "window left" })
map("n", "<C-l>", "<cmd> TmuxNavigateRight<CR>", { desc = "window right" })
map("n", "<C-j>", "<cmd> TmuxNavigateDown<CR>", { desc = "window down" })
map("n", "<C-k>", "<cmd> TmuxNavigateUp<CR>", { desc = "window up" })

-- hover keymaps
map("n", "K", hover.hover, { desc = "hover.nvim" })

map("n", "gK", hover.hover_select, { desc = "hover.nvim (select)" })

map("n", "<C-p>", function()
  hover.hover_switch "previous"
end, { desc = "hover.nvim (previous source)" })

map("n", "<C-n>", function()
  hover.hover_switch "next"
end, { desc = "hover.nvim (next source)" })

-- Hover Mouse support
-- map("n", "<MouseMove>", hover.hover_mouse, { desc = "hover.nvim (mouse)" })
-- vim.o.mousemoveevent = true
