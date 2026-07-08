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
