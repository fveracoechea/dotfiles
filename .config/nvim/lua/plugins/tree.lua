return {
  "nvim-tree/nvim-tree.lua",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    local nvimtree = require "nvim-tree"

    nvimtree.setup {
      hijack_cursor = true,
      view = {
        side = "right",
        width = {
          min = 32,
          max = 52,
        },
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
    }

    local api = require "nvim-tree.api"

    -- Automatically open file upon creation
    api.events.subscribe(api.events.Event.FileCreated, function(file)
      vim.cmd("edit " .. file.fname)
    end)

    -- Workaround when using auto-session
    vim.api.nvim_create_autocmd({ "BufEnter" }, {
      pattern = "NvimTree*",
      callback = function()
        local view = require "nvim-tree.view"

        if not view.is_visible() then
          api.tree.open()
        end
      end,
    })
  end,
}
