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

-- General LSP Keymaps with LspAttach Autocommand
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(args)
    local Snacks = require "snacks"

    local map = vim.keymap.set
    local bufnr = args.buf
    local function opts(desc)
      return { buffer = bufnr, silent = true, desc = "LSP - " .. desc }
    end

    map("n", "K", function()
      vim.lsp.buf.hover { border = "rounded" }
    end, opts "Hover information")

    map("n", "<C-k>", function()
      vim.lsp.buf.signature_help()
    end, opts "Signature help")

    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts "Code Actions")
    map("n", "<leader>rn", vim.lsp.buf.rename, opts "Smart Rename")

    -- LSP information
    map("n", "<leader>lr", function()
      Snacks.picker.lsp_references()
    end, opts "References")

    map("n", "gd", function()
      Snacks.picker.lsp_definitions()
    end, opts "Definition")

    map("n", "<leader>li", function()
      Snacks.picker.lsp_implementations()
    end, opts "Implementation")

    map("n", "<leader>lt", function()
      Snacks.picker.lsp_type_definitions()
    end, opts "Type definition")

    map("n", "<leader>sd", function()
      Snacks.picker.diagnostics_buffer()
    end, opts "Show Buffer Diagnostics")

    map("n", "<leader>sD", function()
      Snacks.picker.diagnostics()
    end, opts "Show diagnostics (all buffers)")

    map("n", "<leader>Dp", vim.diagnostic.goto_prev, opts "Go to previous diagnostic")
    map("n", "<leader>Dn", vim.diagnostic.goto_next, opts "Go to next diagnostic")
  end,
})

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
