local install = require("nvim-treesitter").install {
  "astro",
  "bash",
  "comment",
  "css",
  "diff",
  "dockerfile",
  "editorconfig",
  "git_config",
  "git_rebase",
  "gitattributes",
  "gitcommit",
  "gitignore",
  "graphql",
  "html",
  "http",
  "javascript",
  "jsdoc",
  "json",
  "json5",
  "just",
  "liquid",
  "lua",
  "luadoc",
  "luap",
  "make",
  "markdown",
  "markdown_inline",
  "nginx",
  "nix",
  "printf",
  "python",
  "query",
  "regex",
  "scss",
  "sql",
  "ssh_config",
  "svelte",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "vue",
  "xml",
  "yaml",
}

-- Wait for parser builds in headless sessions too.
if #vim.api.nvim_list_uis() == 0 then
  install:wait(300000)
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
  callback = function(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
