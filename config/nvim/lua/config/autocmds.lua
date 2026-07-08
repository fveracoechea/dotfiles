--- Highlight when yanking
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

--- Empty winbar as a gap between the bufferline and window content
local winbar_filetypes = {
  ["snacks_picker_input"] = true,
  ["snacks_picker_list"] = true,
  ["snacks_explorer"] = true,
  ["alpha"] = true,
  ["NvimTree"] = true,
}

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FileType" }, {
  desc = "Set empty winbar as a gap below the tabline for normal buffers",
  group = vim.api.nvim_create_augroup("winbar-gap", { clear = true }),
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    if winbar_filetypes[ft] then
      vim.wo.winbar = nil
    else
      vim.wo.winbar = " "
    end
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
