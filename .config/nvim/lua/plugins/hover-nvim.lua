---@type NvPluginSpec
return {
  "lewis6991/hover.nvim",
  config = function()
    local hover = require "hover"
    hover.setup {
      init = function()
        require "hover.providers.lsp"
        require "hover.providers.diagnostic"
      end,
      preview_opts = {
        border = "single",
      },
      preview_window = false,
      title = true,
      mouse_providers = {
        "LSP",
      },
      mouse_delay = 1000,
    }
  end,
}
