local conform = require "conform"

conform.setup {
  formatters_by_ft = {
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },
    svelte = { "prettier" },
    css = { "prettier" },
    html = { "prettier" },
    json = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    graphql = { "prettier" },
    lua = { "stylua" },
    python = { "isort", "black" },
  },
  format_on_save = {
    lsp_fallback = true,
    async = false,
    timeout_ms = 500,
  },
}

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  conform.format {
    lsp_fallback = true,
    async = false,
    timeout_ms = 2000,
  }
end, {
  desc = "Code Format (Normal and Visual)",
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  callback = function()
    conform.format {
      lsp_fallback = true,
      async = true,
    }
  end,
})
