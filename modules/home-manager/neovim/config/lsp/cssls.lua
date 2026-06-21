local capabilities = require "utils.lsp-capabilities"

return {
  cmd = { "vscode-css-language-server", "--stdio" },
  capabilities = capabilities,
  filetypes = { "css", "scss", "less" },
  init_options = { provideFormatter = true }, -- needed to enable formatting capabilities
  root_markers = { "package.json", ".git" },
  settings = {
    css = { validate = true },
    scss = { validate = true },
    less = { validate = true },
  },
}
