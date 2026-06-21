--- Highlight when yanking
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

--- Disable mini.completion in snacks picker buffers (explorer, finders, etc.)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "snacks_picker_input", "snacks_picker_list" },
  desc = "Disable mini.completion in snacks picker",
  group = vim.api.nvim_create_augroup("snacks-picker-disable-completion", { clear = true }),
  callback = function()
    vim.b.minicompletion_disable = true
  end,
})
