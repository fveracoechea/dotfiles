local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local null_ls = require "null-ls"

local is_deno = function(utils)
  return utils.root_has_file { "deno.json", "deno.jsonc" }
    and not utils.root_has_file { ".prettierrc", ".prettierrc.json" }
end

local sources = {
  null_ls.builtins.formatting.prettier.with {
    condition = function(utils)
      return not is_deno(utils)
    end,
  },
  null_ls.builtins.diagnostics.deno_lint.with {
    condition = is_deno,
  },
  null_ls.builtins.formatting.deno_fmt.with {
    condition = is_deno,
  },
  null_ls.builtins.formatting.stylua,
}

local opts = {
  sources = sources,
  on_attach = function(client, bufnr)
    if client.supports_method "textDocument/formatting" then
      vim.api.nvim_clear_autocmds {
        group = augroup,
        buffer = bufnr,
      }
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format { bufnr }
        end,
      })
    end
  end,
}

return opts
