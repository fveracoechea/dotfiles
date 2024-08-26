return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
    "folke/todo-comments.nvim",
  },
  config = function()
    local telescope = require "telescope"
    local actions = require "telescope.actions"
    local transform_mod = require("telescope.actions.mt").transform_mod

    local trouble = require "trouble"
    local trouble_telescope = require "trouble.sources.telescope"

    -- or create your custom action
    local custom_actions = transform_mod {
      open_trouble_qflist = function()
        trouble.toggle "quickfix"
      end,
    }

    telescope.setup {
      pickers = {
        buffers = {
          mappings = {
            i = {
              ["<C-x>"] = actions.delete_buffer + actions.move_to_top,
              -- If you'd prefer Telescope not to enter a normal mode when hitting escape and instead exiting.
              ["<esc>"] = actions.close,
            },
          },
        },
      },
      defaults = {
        path_display = { "smart" },
        prompt_prefix = "   ",
        test = "should break",
        -- selection_caret = " ",
        -- entry_prefix = " ",
        sorting_strategy = "ascending",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.60,
          },
          width = 0.90,
          height = 0.90,
        },
        mappings = {
          i = {
            -- move to prev result
            ["<C-k>"] = actions.move_selection_previous,
            -- move to next result
            ["<C-j>"] = actions.move_selection_next,
            ["<C-q>"] = actions.send_selected_to_qflist + custom_actions.open_trouble_qflist,
            ["<C-t>"] = trouble_telescope.open,
            ["<C-h>"] = "which_key",
          },
        },
      },
    }

    -- telescope.load_extension "fzf"
  end,
}
