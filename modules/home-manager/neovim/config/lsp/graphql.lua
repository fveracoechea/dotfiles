local util = require "lspconfig.util"

return {
  cmd = { "graphql-lsp", "server", "-m", "stream" },
  filetypes = {
    "graphql",
    "gql",
    "svelte",
    "javascript",
    "typescript",
    "typescriptreact",
    "javascriptreact",
  },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    on_dir(util.root_pattern(".graphqlrc*", ".graphql.config.*", "graphql.config.*")(fname))
  end,
}
