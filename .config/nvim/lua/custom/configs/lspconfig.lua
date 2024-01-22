local configs = require "plugins.configs.lspconfig"
local on_attach = configs.on_attach
local capabilities = configs.capabilities

local lspconfig = require "lspconfig"

lspconfig.denols.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc", "import_map.json"),
}

lspconfig.tsserver.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  single_file_support = false,
  root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "node_modules"),
  init_options = {
    preferences = {
      disableSuggestions = true,
    },
  },
}

lspconfig.html.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

lspconfig.cssls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

lspconfig.graphql.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
}

lspconfig.tailwindcss.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

lspconfig.relay_lsp.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}
