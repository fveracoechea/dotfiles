local function border(hl_name)
  return {
    { "╭", hl_name },
    { "─", hl_name },
    { "╮", hl_name },
    { "│", hl_name },
    { "╯", hl_name },
    { "─", hl_name },
    { "╰", hl_name },
    { "│", hl_name },
  }
end

return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-buffer", -- source for text in buffer
    "hrsh7th/cmp-path", -- source for file system paths
    {
      "L3MON4D3/LuaSnip",
      -- follow latest release.
      version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
      -- install jsregexp (optional!).
      build = "make install_jsregexp",
    },
    "saadparwaiz1/cmp_luasnip", -- for autocompletion
    "rafamadriz/friendly-snippets", -- useful snippets
    "onsails/lspkind.nvim", -- vs-code like pictograms
  },
  config = function()
    local cmp = require "cmp"

    local luasnip = require "luasnip"

    local lspkind = require "lspkind"

    -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
    require("luasnip.loaders.from_vscode").lazy_load()

    cmp.setup {
      window = {
        completion = {
          side_padding = 1,
          border = border "CmpBorder",
          scrollbar = true,
        },
        documentation = {
          border = border "CmpDocBorder",
          scrollbar = true,
        },
      },

      completion = {
        completeopt = "menu,menuone,preview,noselect",
      },

      -- configure how nvim-cmp interacts with snippet engine
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },

      mapping = cmp.mapping.preset.insert {
        ["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
        ["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
        ["<C-e>"] = cmp.mapping.abort(), -- close completion window
        ["<CR>"] = cmp.mapping.confirm { select = false },
      },

      -- sources for autocompletion
      sources = cmp.config.sources {
        { name = "nvim_lsp" },
        { name = "luasnip" }, -- snippets
        { name = "buffer" }, -- text within current buffer
        { name = "path" }, -- file system paths
      },

      -- configure lspkind for vs-code like pictograms in completion menu
      formatting = {
        expandable_indicator = true,
        fields = { "kind", "abbr", "menu" },
        format = lspkind.cmp_format {
          maxwidth = 50,
          ellipsis_char = "...",
          symbol_map = {
            Namespace = "󰌗",
            Text = "󰉿",
            Method = "󰆧",
            Function = "󰆧",
            Constructor = "",
            Field = "󰜢",
            Variable = "󰀫",
            Class = "󰠱",
            Interface = "",
            Module = "",
            Property = "󰜢",
            Unit = "󰑭",
            Value = "󰎠",
            Enum = "",
            Keyword = "󰌋",
            Snippet = "",
            Color = "󰏘",
            File = "󰈚",
            Reference = "󰈇",
            Folder = "󰉋",
            EnumMember = "",
            Constant = "󰏿",
            Struct = "󰙅",
            Event = "",
            Operator = "󰆕",
            TypeParameter = "󰊄",
            Table = "",
            Object = "󰅩",
            Tag = "",
            Array = "[]",
            Boolean = "",
            Number = "",
            Null = "󰟢",
            Supermaven = "",
            String = "󰉿",
            Calendar = "",
            Watch = "󰥔",
            Package = "",
            Copilot = "",
            Codeium = "",
            TabNine = "",
          },
        },
      },
    }
  end,
}
