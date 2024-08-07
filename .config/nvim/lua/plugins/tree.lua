return {
  "nvim-tree/nvim-tree.lua",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    local nvimtree = require "nvim-tree"

    nvimtree.setup {
      hijack_cursor = true,
      view = {
        side = "right",
        width = 42,
        relativenumber = true,
        preserve_window_proportions = true,
      },

      renderer = {
        indent_markers = {
          enable = true,
        },
        icons = {
          glyphs = {
            folder = {
              arrow_closed = "",
              arrow_open = "",
            },
          },
        },
      },

      actions = {
        open_file = {
          -- disable window_picker for explorer to work well with window splits
          window_picker = {
            enable = false,
          },
        },
      },

      filters = {
        custom = { ".DS_Store", "^.git$" },
      },

      git = {
        ignore = false,
      },

      -- on_attach = function(bufnr)
      --   local function opts(desc)
      --     return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      --   end
      --   local ok, api = pcall(require, "nvim-tree.api")
      --   assert(ok, "api module is not found")
      --   vim.keymap.set("n", "<CR>", api.node.open.tab_drop, opts "Tab drop")
      -- end,
    }

    -- local view = require "nvim-tree.view"
    -- local api = require "nvim-tree.api"
    -- local augroup = vim.api.nvim_create_augroup
    -- local autocmd = vim.api.nvim_create_autocmd
    --
    -- -- save nvim-tree window width on WinResized event
    -- augroup("save_nvim_tree_width", { clear = true })
    -- autocmd("WinResized", {
    --   group = "save_nvim_tree_width",
    --   pattern = "*",
    --   callback = function()
    --     local filetree_winnr = view.get_winnr()
    --     if filetree_winnr ~= nil and vim.tbl_contains(vim.v.event["windows"], filetree_winnr) then
    --       vim.t["filetree_width"] = vim.api.nvim_win_get_width(filetree_winnr)
    --     end
    --   end,
    -- })
    --
    -- -- restore window size when opening nvim-tree
    -- api.events.subscribe(api.events.Event.TreeOpen, function()
    --   if vim.t["filetree_width"] ~= nil then
    --     view.resize(vim.t["filetree_width"])
    --   end
    -- end)
  end,
}
