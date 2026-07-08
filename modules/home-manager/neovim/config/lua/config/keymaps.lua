local Snacks = require "snacks"
local map = Snacks.keymap.set
-- ============================================================================
-- CORE VIM MAPPINGS
-- ============================================================================

-- Save file
map({ "n", "i" }, "<Esc>", "<CMD>w<CR><Esc>", { desc = "Save file" })

-- Select all
vim.keymap.set("n", "<C-a>", "ggVG", { desc = "Select All" })

-- Window management
map("n", "<leader>\\", "<C-w>v", { desc = "Split window vertically" })
map("n", "<leader>-", "<C-w>s", { desc = "Split window horizontally" })
map("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })

-- ============================================================================
-- PLUGIN MAPPINGS
-- ============================================================================

-- Yazi file manager
map("n", "<C-n>", "<CMD>Yazi cwd<CR>", { desc = "Open the file manager in nvim's working directory" })
map("n", "<C-y>", "<CMD>Yazi<CR>", { desc = "Open yazi at the current file" })

-- CodeSnap screenshots
map("v", "<leader>cc", "<CMD>CodeSnap<CR>", { desc = "Save selected code snapshot into clipboard" })
map("v", "<leader>cs", "<CMD>CodeSnapSave<CR>", { desc = "Save selected code snapshot in ~/Pictures" })

-- ============================================================================
-- SNACKS PLUGIN MAPPINGS
-- ============================================================================

map("n", "<leader>lsp", ":lsp restart<CR>", { desc = "Resart LSP Servers" })

-- LSP keymaps (snacks.keymap applies these to buffers with matching LSP clients)

map("n", "K", function()
  vim.lsp.buf.hover { border = "rounded" }
end, { lsp = { method = "textDocument/hover" }, desc = "LSP - Hover information" })

map("n", "<C-k>", function()
  vim.lsp.buf.signature_help()
end, { lsp = { method = "textDocument/signatureHelp" }, desc = "LSP - Signature help" })

map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {
  lsp = { method = "textDocument/codeAction" },
  desc = "LSP - Code Actions",
})

map("n", "<leader>rn", vim.lsp.buf.rename, { lsp = { method = "textDocument/rename" }, desc = "LSP - Smart Rename" })

map("n", "<leader>lr", function()
  Snacks.picker.lsp_references()
end, { lsp = { method = "textDocument/references" }, desc = "LSP - References" })

map("n", "gd", function()
  Snacks.picker.lsp_definitions()
end, { lsp = { method = "textDocument/definition" }, desc = "LSP - Definition" })

map("n", "<leader>li", function()
  Snacks.picker.lsp_implementations()
end, { lsp = { method = "textDocument/implementation" }, desc = "LSP - Implementation" })

map("n", "<leader>lt", function()
  Snacks.picker.lsp_type_definitions()
end, { lsp = { method = "textDocument/typeDefinition" }, desc = "LSP - Type definition" })

map("n", "<leader>sd", function()
  Snacks.picker.diagnostics_buffer()
end, { lsp = {}, desc = "LSP - Show Buffer Diagnostics" })

map("n", "<leader>sD", function()
  Snacks.picker.diagnostics()
end, { lsp = {}, desc = "LSP - Show diagnostics (all buffers)" })

map("n", "<leader>Dp", vim.diagnostic.goto_prev, { lsp = {}, desc = "LSP - Go to previous diagnostic" })
map("n", "<leader>Dn", vim.diagnostic.goto_next, { lsp = {}, desc = "LSP - Go to next diagnostic" })

-- Dashboard

map("n", "<leader>;", function()
  Snacks.dashboard()
end, { desc = "Dashboard" })

-- File and text finding

map("n", "<leader>ff", function()
  Snacks.picker.files()
end, { desc = "Find files in cwd" })

map("n", "<leader>fr", function()
  Snacks.picker.recent()
end, { desc = "Find recent files" })

map("n", "<leader>fs", function()
  Snacks.picker.grep()
end, { desc = "Find string in cwd" })

map("n", "<leader>fc", function()
  Snacks.picker.grep_buffers()
end, { desc = "Find in current buffer" })

map("n", "<leader>fw", function()
  Snacks.picker.grep_word()
end, { desc = "Find string under cursor in Workspace" })

map("n", "<leader>fa", function()
  Snacks.picker.files { hidden = true, no_ignore = true }
end, { desc = "Find all files" })

-- Explorer

map("n", "<leader>e", function()
  Snacks.picker.explorer()
end, { desc = "Open the file manager at the current file" })

-- Buffer management

map("n", "<leader>x", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })

map("n", "<leader>xo", function()
  Snacks.bufdelete.other()
end, { desc = "Delete Other Buffers" })

map("n", "<Tab>", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
map("n", "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })

for i = 1, 9 do
  map("n", "<leader>" .. i, function()
    vim.cmd("BufferLineGoToBuffer " .. i)
  end, { desc = "Buffer " .. i })
end

-- Git integration

map("n", "<leader>gb", function()
  Snacks.git.blame_line()
end, { desc = "Git Blame Line" })

map("n", "<leader>gB", function()
  Snacks.gitbrowse()
end, { desc = "Git Browse" })

map("n", "<leader>gf", function()
  Snacks.lazygit.log_file()
end, { desc = "Lazygit Current File History" })

map("n", "<leader>gl", function()
  Snacks.lazygit.log()
end, { desc = "Lazygit Log (cwd)" })

-- GitHub issues and pull requests (requires gh CLI)

map("n", "<leader>gi", function()
  Snacks.picker.gh_issue()
end, { desc = "GitHub Issues (open)" })

map("n", "<leader>gI", function()
  Snacks.picker.gh_issue { state = "all" }
end, { desc = "GitHub Issues (all)" })

map("n", "<leader>gp", function()
  Snacks.picker.gh_pr()
end, { desc = "GitHub Pull Requests (open)" })

map("n", "<leader>gP", function()
  Snacks.picker.gh_pr { state = "all" }
end, { desc = "GitHub Pull Requests (all)" })

-- Notifications

map("n", "<leader>nh", function()
  Snacks.notifier.show_history()
end, { desc = "Notification History" })

map("n", "<leader>nd", function()
  Snacks.notifier.hide()
end, { desc = "Dismiss All Notifications" })

-- Word references
map("n", "]]", function()
  Snacks.words.jump(vim.v.count1)
end, { desc = "Next Reference" })

map("n", "[[", function()
  Snacks.words.jump(-vim.v.count1)
end, { desc = "Prev Reference" })

-- Zen mode
map("n", "<leader>z", function()
  Snacks.zen()
end, { desc = "Toggle Zen Mode" })

map("n", "<leader>Z", function()
  Snacks.zen.zoom()
end, { desc = "Toggle Zoom" })

-- Scratch buffer

map("n", "<leader>.", function()
  Snacks.scratch()
end, { desc = "Toggle Scratch Buffer" })

map("n", "<leader>S", function()
  Snacks.scratch.select()
end, { desc = "Select Scratch Buffer" })

-- Todo comments

map("n", "<leader>st", function()
  Snacks.picker.todo_comments()
end, { desc = "Show TODO comments" })

map("n", "<leader>sT", function()
  Snacks.picker.todo_comments { keywords = { "TODO", "FIX", "FIXME" } }
end, { desc = "TODO/FIX/FIXME" })

-- ============================================================================
-- MINI PLUGIN MAPPINGS
-- ============================================================================

-- Session management

map("n", "<leader>wr", function()
  local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  require("mini.sessions").read(cwd)
end, { desc = "Read session" })

map("n", "<leader>ws", function()
  local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  require("mini.sessions").write(cwd)
end, { desc = "Write session" })

map("n", "<leader>wd", function()
  local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  require("mini.sessions").delete(cwd)
end, { desc = "Delete session" })

-- Mini.diff keymaps

map("n", "]h", function()
  require("mini.diff").goto_hunk "next"
end, { desc = "Next hunk" })

map("n", "[h", function()
  require("mini.diff").goto_hunk "prev"
end, { desc = "Prev hunk" })

-- Mini.completion keymaps

local MiniSnippets = require "mini.snippets"

map("i", "<C-j>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  else
    return "<C-j>"
  end
end, { desc = "Next completion item", expr = true })

map("i", "<C-k>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-p>"
  else
    return "<C-k>"
  end
end, { desc = "Previous completion item", expr = true })

map("i", "<C-e>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-e>"
  else
    return "<C-e>"
  end
end, { desc = "Close completion menu", expr = true })

-- Fixed Tab and Shift-Tab for completion navigation and snippet expansion

map("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  elseif MiniSnippets.can_expand() then
    MiniSnippets.expand()
    return ""
  elseif MiniSnippets.can_jump "next" then
    MiniSnippets.jump "next"
    return ""
  else
    return "<Tab>"
  end
end, { desc = "Next completion, expand snippet, or Tab", expr = true })

map("i", "<S-Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-p>"
  elseif MiniSnippets.can_jump "prev" then
    MiniSnippets.jump "prev"
    return ""
  else
    return "<S-Tab>"
  end
end, { desc = "Previous completion, jump prev, or Shift-Tab", expr = true })

-- OPENCODE

map({ "n", "x" }, "<leader>oa", function()
  require("opencode").ask("@this: ", { submit = true })
end, { desc = "Ask about this" })

map({ "n", "x" }, "<leader>o+", function()
  require("opencode").prompt "@this"
end, { desc = "Add this" })

map({ "n", "x" }, "<leader>os", function()
  require("opencode").select()
end, { desc = "Select prompt" })

map("n", "<leader>ot", function()
  require("opencode").toggle()
end, { desc = "Toggle embedded" })

map("n", "<leader>oc", function()
  require("opencode").command()
end, { desc = "Select command" })

map("n", "<leader>on", function()
  require("opencode").command "session_new"
end, { desc = "New session" })

map("n", "<leader>oi", function()
  require("opencode").command "session_interrupt"
end, { desc = "Interrupt session" })

map("n", "<leader>oA", function()
  require("opencode").command "agent_cycle"
end, { desc = "Cycle selected agent" })

map("n", "<S-C-u>", function()
  require("opencode").command "messages_half_page_up"
end, { desc = "Messages half page up" })

map("n", "<S-C-d>", function()
  require("opencode").command "messages_half_page_down"
end, { desc = "Messages half page down" })

-- ============================================================================
-- LINT PLUGIN MAPPINGS
-- ============================================================================

map("n", "<leader>ll", function()
  require("lint").try_lint()
end, { desc = "Trigger linting for current file" })
