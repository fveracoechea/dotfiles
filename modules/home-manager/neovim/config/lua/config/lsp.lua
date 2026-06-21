-- appropriately highlight codefences returned from denols
vim.g.markdown_fenced_languages = {
  "ts=typescript",
}

vim.diagnostic.config {
  underline = true,
  severity_sort = true,
  virtual_text = false,
  virtual_lines = { current_line = true },
  update_in_insert = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅙 ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = "󰠠 ",
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "ErrorMsg",
      [vim.diagnostic.severity.WARN] = "WarningMsg",
    },
  },
  float = {
    border = "rounded",
    source = true,
  },
}

-- LSP keymaps (snacks.keymap applies these to buffers with matching LSP clients)
local Snacks = require "snacks"
local map = Snacks.keymap.set

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

-- Enable the servers listed here that have been configured in `lua/lsp/*`
vim.lsp.enable {
  "biome",
  "cssls",
  "denols",
  "eslint",
  "graphql",
  "html",
  "jsonls",
  "lua_ls",
  "nixd",
  "relay_lsp",
  "stylelint_lsp",
  "tailwindcss",
  "ts_ls",
}
