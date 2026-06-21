local util = require "lspconfig.util"

return {
  cmd = { "relay-compiler", "lsp" },
  root_dir = util.root_pattern "relay.config.json",
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
}
