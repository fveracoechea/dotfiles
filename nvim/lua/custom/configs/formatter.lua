local conform = require "conform"

local formatOptions = {
  lsp_fallback = true,
  async = false,
  timeout_ms = 2000,
}

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
  format_on_save = formatOptions,
}

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  conform.format(formatOptions)
end, {
  desc = "Code Format (Normal and Visual)",
})

-- vim.api.nvim_create_autocmd({ "BufWritePost" }, {
--   callback = function()
--     conform.format(formatOptions)
--   end,
-- })
