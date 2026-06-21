require("lsp-file-operations").setup()

local capabilities = vim.tbl_deep_extend(
  "force",
  vim.lsp.protocol.make_client_capabilities(),
  require("cmp_nvim_lsp").default_capabilities(),
  require("lsp-file-operations").default_capabilities()
)

capabilities.textDocument.completion.completionItem.snippetSupport = true

return capabilities
