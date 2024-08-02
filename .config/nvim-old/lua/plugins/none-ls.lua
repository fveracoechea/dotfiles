local getOptions = function()
  local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
  local null_ls = require "null-ls"

  local sources = {
    null_ls.builtins.formatting.shfmt,
    null_ls.builtins.formatting.prettierd,
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.diagnostics.codespell,

    require("none-ls.diagnostics.eslint_d").with {
      condition = function(utils)
        return utils.root_has_file { ".eslintrc.json", ".eslintrc", "eslint.config.js" }
      end,
    },

    require("none-ls.code_actions.eslint_d").with {
      condition = function(utils)
        return utils.root_has_file { ".eslintrc.json", ".eslintrc", "eslint.config.js" }
      end,
    },
  }

  return {
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
            vim.lsp.buf.format { async = false }
          end,
        })
      end
    end,
  }
end

---@type NvPluginSpec
return {
  {
    "nvimtools/none-ls.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvimtools/none-ls-extras.nvim",
    },
    opts = getOptions,
  },
}
