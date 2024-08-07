return {
  "neovim/nvim-lspconfig",
  event = "VeryLazy",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
  },
  config = function()
    local x = vim.diagnostic.severity

    -- Sets global diagnostic config
    vim.diagnostic.config {
      virtual_text = { prefix = "" },
      -- Change the Diagnostic symbols in the sign column (gutter)
      signs = { text = { [x.ERROR] = "󰅙 ", [x.WARN] = " ", [x.INFO] = " ", [x.HINT] = "󰠠 " } },
      underline = true,
      float = { border = "single" },
    }

    require "config.lsp.servers"
  end,
}
