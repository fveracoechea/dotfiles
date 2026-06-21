require("mini.sessions").setup {
  file = "",
  autowrite = true,
  directory = "~/.config/nvim",
}

require("mini.pairs").setup {}

require("mini.surround").setup {
  mappings = {
    add = "<leader>sa", -- Add surrounding in Normal and Visual modes
    delete = "<leader>sd", -- Delete surrounding
    find = "<leader>sf", -- Find surrounding (to the right)
    find_left = "<leader>sF", -- Find surrounding (to the left)
    highlight = "<leader>sh", -- Highlight surrounding
    replace = "<leader>sr", -- Replace surrounding

    suffix_last = "", -- Suffix to search with "prev" method
    suffix_next = "", -- Suffix to search with "next" method
  },
}

require("mini.comment").setup {}
require("mini.diff").setup {}

local gen_loader = require("mini.snippets").gen_loader

require("mini.snippets").setup {
  mappings = {
    expand = "", -- disable default <C-j> to avoid conflict with cmp navigation
  },
  snippets = {
    --   Load custom file with global snippets first (adjust for Windows)
    gen_loader.from_file "~/.config/nvim/snippets/global.json",
    -- Load snippets based on current language by reading files from
    -- "snippets/" subdirectories from 'runtimepath' directories.
    gen_loader.from_lang(),
  },
}

require("mini.icons").setup {
  style = "glyph",
  lsp = {
    ellipsis_char = { glyph = "…", hl = "MiniIconsOrange" },
    copilot = { glyph = "", hl = "MiniIconsGreen" },
    ["function"] = { glyph = "󰊕", hl = "MiniIconsBlue" },
    snippet = { glyph = "", hl = "MiniIconsYellow" },
  },
}

local MiniClue = require "mini.clue"

MiniClue.setup {
  window = {
    delay = 500,
    config = {
      width = 50,
    },
  },
  triggers = {
    -- Leader triggers
    { mode = "n", keys = "<Leader>" },
    { mode = "x", keys = "<Leader>" },
    -- Built-in completion
    { mode = "i", keys = "<C-x>" },
    -- `g` key
    { mode = "n", keys = "g" },
    { mode = "x", keys = "g" },
    -- Marks
    { mode = "n", keys = "'" },
    { mode = "n", keys = "`" },
    { mode = "x", keys = "'" },
    { mode = "x", keys = "`" },
    -- Registers
    { mode = "n", keys = '"' },
    { mode = "x", keys = '"' },
    { mode = "i", keys = "<C-r>" },
    { mode = "c", keys = "<C-r>" },
    -- Window commands
    { mode = "n", keys = "<C-w>" },
    -- `z` key
    { mode = "n", keys = "z" },
    { mode = "x", keys = "z" },
  },
  clues = {
    -- Enhance this by adding descriptions for <Leader> mapping groups
    MiniClue.gen_clues.builtin_completion(),
    MiniClue.gen_clues.g(),
    MiniClue.gen_clues.marks(),
    MiniClue.gen_clues.registers(),
    MiniClue.gen_clues.windows(),
    MiniClue.gen_clues.z(),
  },
}
