local conform = require "conform"

local js_formatters = { "prettier", "biome-check", "deno_fmt", stop_after_first = true }

conform.setup {
  formatters = {
    deno_fmt = {
      require_cwd = true,
    },
    prettier = {
      require_cwd = true,
    },
    biome = {
      require_cwd = true,
    },
  },
  formatters_by_ft = {
    javascript = js_formatters,
    typescript = js_formatters,
    javascriptreact = js_formatters,
    typescriptreact = js_formatters,
    css = js_formatters,
    html = js_formatters,
    json = js_formatters,
    jsonc = js_formatters,
    yaml = js_formatters,
    markdown = js_formatters,
    astro = js_formatters,
    vue = js_formatters,
    svelte = js_formatters,
    graphql = js_formatters,
    liquid = { "prettier" },
    lua = { "stylua" },
    python = { "isort", "black" },
    nix = { "alejandra" },
  },
  format_on_save = {
    lsp_format = "fallback",
    timeout_ms = 1200,
  },
}
