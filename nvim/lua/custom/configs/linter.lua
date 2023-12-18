local lint = require "lint"

lint.linters_by_ft = {
  javascript = { "eslint" },
  javascriptreact = { "eslint" },
  typescript = { "eslint" },
  typescriptreact = { "eslint" },
  svelte = { "eslint" },
  python = { "pylint" },
}

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
  callback = function()
    lint.try_lint()
  end,
})

vim.keymap.set("n", "<leader>cl", function()
  lint.try_lint()
end, {
  desc = "Code Linting on current file (Normal)",
})
