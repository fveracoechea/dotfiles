local configs = require "plugins.configs.lspconfig"
local on_attach = configs.on_attach
local capabilities = configs.capabilities

--Enable (broadcasting) snippet capability for completion
capabilities.textDocument.completion.completionItem.snippetSupport = true

local lspconfig = require "lspconfig"

lspconfig.jsonls.setup {
  capabilities = capabilities,
  filetypes = { "json", "jsonc" },
  settings = {
    json = {
      -- Schemas https://www.schemastore.org
      schemas = {
        {
          fileMatch = { "package.json" },
          url = "https://json.schemastore.org/package.json",
        },
        {
          fileMatch = { "tsconfig*.json" },
          url = "https://json.schemastore.org/tsconfig.json",
        },
        {
          fileMatch = {
            ".prettierrc",
            ".prettierrc.json",
            "prettier.config.json",
          },
          url = "https://json.schemastore.org/prettierrc.json",
        },
        {
          fileMatch = {
            ".eslintrc",
            ".eslintrc.json",
            "eslint.config.json",
          },
          url = "https://json.schemastore.org/eslintrc.json",
        },
        {
          fileMatch = { ".eslintrc", ".eslintrc.json" },
          url = "https://json.schemastore.org/eslintrc.json",
        },
        {
          fileMatch = { ".babelrc", ".babelrc.json", "babel.config.json" },
          url = "https://json.schemastore.org/babelrc.json",
        },
        {
          fileMatch = { "lerna.json" },
          url = "https://json.schemastore.org/lerna.json",
        },
        {
          fileMatch = { "now.json", "vercel.json" },
          url = "https://json.schemastore.org/now.json",
        },
        {
          fileMatch = {
            ".stylelintrc",
            ".stylelintrc.json",
            "stylelint.config.json",
          },
          url = "http://json.schemastore.org/stylelintrc.json",
        },
      },
    },
  },
}

lspconfig.denols.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
}

lspconfig.tsserver.setup {
  on_attach = function(client, bufnr)
    if lspconfig.util.root_pattern("deno.json", "deno.jsonc")(vim.fn.getcwd()) then
      if client.name == "tsserver" then
        client.stop()
        return
      end
    end

    return on_attach(client, bufnr)
  end,
  capabilities = capabilities,
  single_file_support = false,
  root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "node_modules"),
  init_options = {
    preferences = {
      disableSuggestions = true,
    },
  },
}

lspconfig.tailwindcss.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    tailwindCSS = {
      classAttributes = { "class", "className", "class:list", "classList", "ngClass", "classNames", "styles" },
      experimental = {
        -- https://github.com/paolotiu/tailwind-intellisense-regex-list
        classRegex = {
          -- clsx
          { "clsx\\(([^]*)\\)", "(?:'|\"|`)([^\"'`]*)(?:'|\"|`)" },
          -- class-variance-authority
          { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
          { "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
          -- Plain Javascript Object
          --  const styles = {
          --   wrapper: 'flex flex-col',
          --   navItem: 'relative mb-2 md:mb-0',
          --   bullet: 'absolute w-2 h-2 2xl:w-4 2xl:h-4 bg-red rounded-full',
          -- };
          { ":\\s*?[\"'`]([^\"'`]*).*?," },
          -- JavaScript string variable with keywords
          -- const styles = "bg-red-500 text-white";
          -- let Classes = "p-4 rounded";
          -- var classnames = "flex justify-center";
          -- const buttonStyles = "bg-blue-500 hover:bg-blue-700";
          -- let formClasses = "space-y-4";
          -- var inputClassnames = "border-2 border-gray-300";
          -- styles += 'rounded';
          {
            "(?:\\b(?:const|let|var)\\s+)?[\\w$_]*(?:[Ss]tyles|[Cc]lasses|[Cc]lassnames)[\\w\\d]*\\s*(?:=|\\+=)\\s*['\"]([^'\"]*)['\"]",
          },
          -- classList
          { "classList={{([^;]*)}}", "\\s*?[\"'`]([^\"'`]*).*?:" },
        },
      },
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
  filetypes = {
    "graphql",
    "gql",
    "svelte",
    "javascript",
    "typescript",
    "typescriptreact",
    "javascriptreact",
  },
}

lspconfig.relay_lsp.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = lspconfig.util.root_pattern "relay.config.json",
}

lspconfig.eslint.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}
