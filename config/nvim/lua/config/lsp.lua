-- enable mdx
vim.filetype.add {
  extension = {
    mdx = "markdown",
  },
}

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

-- Disable document_color globally: nvim 0.12.3 has a bug in document_color.lua:225
-- where assert(get_client_by_id(id)) fires on LSP reload before on_detach cleans up stale client_state
vim.lsp.document_color.enable(false)

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
  "oxfmt",
  "oxlint",
  "relay_lsp",
  "stylelint_lsp",
  "tailwindcss",
  "ts_ls",
}
