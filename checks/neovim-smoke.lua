local function check_config()
  assert(vim.v.errmsg == "", vim.v.errmsg)
  assert(#(vim.g.dotfiles_smoke_errors or {}) == 0, vim.inspect(vim.g.dotfiles_smoke_errors))

  local lock = vim.json.decode(table.concat(vim.fn.readfile(vim.fn.stdpath "config" .. "/nvim-pack-lock.json"), "\n"))
  assert(#vim.pack.get() == vim.tbl_count(lock.plugins), "Plugin catalog differs from the lockfile")
  if vim.env.DOTFILES_PACK_GIT_TEST == "1" then
    local lock_path = vim.fn.stdpath "config" .. "/nvim-pack-lock.json"
    assert(vim.uv.fs_lstat(lock_path).type == "link", "Lockfile is not a writable checkout link")
    for name, plugin in pairs(lock.plugins) do
      local directory = vim.fn.stdpath "data" .. "/site/pack/core/opt/" .. name
      local revision = vim.system({ "git", "-C", directory, "rev-parse", "HEAD" }, { text = true }):wait()
      assert(revision.code == 0 and vim.trim(revision.stdout) == plugin.rev, "Wrong plugin revision: " .. name)
    end
    vim.pack.update(nil, { offline = true, target = "lockfile", force = true })
    assert(vim.uv.fs_lstat(lock_path).type == "link", "Plugin update replaced the lockfile link")
    local updated = vim.json.decode(table.concat(vim.fn.readfile(lock_path), "\n"))
    assert(vim.deep_equal(lock, updated), "Offline update changed plugin revisions")
  end

  for _, command in ipairs {
    "cc",
    "tree-sitter",
    "curl",
    "tar",
    "git",
    "nixd",
    "alejandra",
    "graphql-lsp",
    "stylelint-language-server",
    "biome",
    "lua-language-server",
    "oxfmt",
    "oxlint",
    "tsc",
    "stylua",
    "prettier",
    "isort",
    "black",
    "magick",
  } do
    local path = vim.fn.exepath(command)
    assert(path:match "^/nix/store/", "Missing Nix dependency: " .. command .. " at " .. path)
  end

  for _, name in ipairs {
    "biome",
    "cssls",
    "eslint",
    "graphql",
    "html",
    "jsonls",
    "lua_ls",
    "nixd",
    "oxfmt",
    "oxlint",
    "stylelint_lsp",
    "tailwindcss",
    "tsc",
  } do
    assert(vim.lsp.is_enabled(name), "Disabled LSP: " .. name)
    local server = vim.lsp.config[name]
    assert(server and server.cmd, "Missing LSP config: " .. name)
    if type(server.cmd) == "table" then
      assert(vim.fn.executable(server.cmd[1]) == 1, "Missing LSP executable: " .. server.cmd[1])
    end
  end
  assert(not vim.lsp.is_enabled "qmlls")
  assert(not vim.lsp.is_enabled "denols")
  assert(not vim.lsp.is_enabled "relay_lsp")

  local treesitter = table.concat(vim.fn.readfile(vim.fn.stdpath "config" .. "/lua/plugins/treesitter.lua"), "\n")
  local parser_dir = vim.fn.stdpath "data" .. "/site/parser/"
  for language in treesitter:gmatch '\n  "([a-z_0-9]+)",' do
    local path = parser_dir .. language .. ".so"
    assert(vim.fn.filereadable(path) == 1, "Parser not installed: " .. language)
    vim.treesitter.language.add(language, { path = path })
    assert(vim.treesitter.get_string_parser("", language):parse(), "Parser cannot load: " .. language)
  end

  assert(vim.fn.exists ":CodeSnap" == 2)
  assert(pcall(require, "codesnap"))
  assert(vim.fn.exists ":Herdr" == 2)
  assert(require("herdr-nvim").config.clear_after_send == true)
  for _, suffix in ipairs { "c", "l", "s", "S" } do
    local mapping = vim.fn.maparg(vim.g.mapleader .. "h" .. suffix, "n", false, true)
    assert(mapping.desc:match "herdr%-nvim", "Missing Herdr mapping: " .. suffix)
  end
  assert(#vim.fn.maparg(vim.g.mapleader .. "hc", "x") > 0)
  assert(#vim.fn.maparg(vim.g.mapleader .. "ll", "n") == 0, "Unused lint mapping remains")
  for _, key in ipairs { "<C-n>", "<C-y>" } do
    assert(type(vim.fn.maparg(key, "n", false, true).callback) == "function", "Missing explorer mapping")
  end
  assert(type(Snacks.explorer) == "table" or type(Snacks.explorer) == "function")

  local text = "dotfiles_no_matching_snippet"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { text })
  vim.api.nvim_win_set_cursor(0, { 1, #text - 1 })
  assert(vim.fn.maparg("<Tab>", "i", false, true).callback() == "<Tab>")
  assert(vim.fn.maparg("<S-Tab>", "i", false, true).callback() == "<S-Tab>")
  local formatters = require("conform").formatters_by_ft
  assert(formatters.nix[1] == "alejandra")
  assert(formatters.qml == nil)

  local project = vim.fn.tempname()
  vim.fn.mkdir(project .. "/src", "p")
  vim.fn.writefile(
    { '{ "compilerOptions": { "strict": true, "noEmit": true }, "include": ["src"] }' },
    project .. "/tsconfig.json"
  )
  vim.fn.writefile({ "const count: number = 1;" }, project .. "/src/main.ts")
  vim.fn.writefile({ "{ outputs = _: {}; }" }, project .. "/flake.nix")
  vim.cmd.cd(project)

  local function open_with_server(file, name)
    vim.cmd.edit(file)
    local buffer = vim.api.nvim_get_current_buf()
    assert(
      vim.wait(15000, function()
        for _, client in ipairs(vim.lsp.get_clients { bufnr = buffer, name = name }) do
          if client.initialized then
            return true
          end
        end
        return false
      end),
      "Language server did not initialize: " .. name
    )
    assert(vim.v.errmsg == "", vim.v.errmsg)
  end

  open_with_server(project .. "/src/main.ts", "tsc")
  open_with_server(project .. "/flake.nix", "nixd")
  assert(#(vim.g.dotfiles_smoke_errors or {}) == 0, vim.inspect(vim.g.dotfiles_smoke_errors))
end

local ok, error_message = pcall(check_config)
if not ok then
  io.stderr:write(tostring(error_message) .. "\n")
  vim.cmd "cquit 1"
end
print "Neovim runtime checks passed"
vim.cmd "qa!"
