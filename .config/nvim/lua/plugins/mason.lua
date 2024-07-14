---@type NvPluginSpec
return {
  "williamboman/mason.nvim",
  opts = {
    ensure_installed = {
      "lua-language-server",
      "stylua",
      "eslint-lsp",
      "eslint_d",
      "graphql-language-service-cli",
      "html-lsp",
      "prettierd",
      "tailwindcss-language-server",
      "typescript-language-server",
      "deno",
      "css-lsp",
      "json-lsp",
      "codespell",
      "nginx-language-server",
      "editorconfig-checker",
    },
  },
}
