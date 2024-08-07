-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local map = vim.keymap.set

-- Save file
map("n", "<C-s>", "<CMD>w<CR>", { desc = "file save" })

-- Nvim Tree
map("n", "<C-n>", "<CMD>NvimTreeToggle<CR>", { desc = "NvimTree toggle window" })
map("n", "<leader>t", "<CMD>NvimTreeFocus<CR>", { desc = "NvimTree focus window" })
map("n", "<leader>e", "<CMD>NvimTreeFindFile<CR>", { desc = "Focus current buffer in NvimTree." })

-- Comment
map("n", "<leader>/", "gcc", { desc = "comment toggle", remap = true })
map("v", "<leader>/", "gc", { desc = "comment toggle", remap = true })

-- Window management
map("n", "<leader>\\", "<C-w>v", { desc = "Split window vertically" })
map("n", "<leader>-", "<C-w>s", { desc = "Split window horizontally" })
map("n", "<leader>x", "<CMD>close<CR>", { desc = "Close current split" })
map("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })

-- Telescope
map("n", "<leader>ff", "<CMD>Telescope find_files<CR>", { desc = "Find files in cwd" })
map("n", "<leader>fr", "<CMD>Telescope oldfiles<CR>", { desc = "Find recent files" })
map("n", "<leader>fs", "<CMD>Telescope live_grep<CR>", { desc = "Find string in cwd" })
map("n", "<leader>ft", "<CMD>TodoTelescope<CR>", { desc = "Find todos" })
map("n", "<leader>fc", "<CMD>Telescope current_buffer_fuzzy_find<CR>", { desc = "Find in current buffer" })
map("n", "<leader>fw", "<CMD>Telescope grep_string<CR>", { desc = "Find string under cursor in Workspace" })
map(
  "n",
  "<leader>b",
  "<CMD>Telescope buffers sort_mru=true ignore_current_buffer=true<CR>",
  { desc = "Find open buffers" }
)
map(
  "n",
  "<leader>fa",
  "<CMD>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
  { desc = "Find all files" }
)

-- Sessions
map("n", "<leader>wr", "<CMD>SessionRestore<CR>", { desc = "Restore session for cwd" })
map("n", "<leader>ws", "<CMD>SessionSave<CR>", { desc = "Save session for auto session root dir" })

-- Format file
vim.keymap.set({ "n", "v" }, "<leader>mp", function()
  require("conform").format {
    lsp_fallback = true,
    async = false,
    timeout_ms = 1000,
  }
end, { desc = "Format file or range (in visual mode)" })
