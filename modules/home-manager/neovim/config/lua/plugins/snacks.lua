require("snacks").setup {
  dashboard = {
    enabled = true,
    sections = {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
      {
        section = "terminal",
        indent = 2,
        padding = 1,
        icon = " ",
        title = "Git Status",
        cmd = "git --no-pager diff --stat -B -M -C",
        height = 10,
        ttl = 5 * 60,
        enabled = Snacks.git.get_root() ~= nil,
      },
      {
        section = "terminal",
        cmd = "fastfetch  -l none",
        pane = 2,
        indent = 2,
        height = 18,
      },
    },
  },

  preset = {
    keys = {
      { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
      { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
      { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
      { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
      { icon = " ", key = "s", desc = "Restore Session", section = ":lua require('mini.sessions').read()" },
      { icon = " ", key = "q", desc = "Quit", action = ":qa" },
    },
  },

  indent = {
    enabled = true,
    char = "┊",
  },

  scope = {
    enabled = true,
    char = "┊",
  },

  picker = {
    enabled = true,
    sources = {
      explorer = {
        hidden = true,
        ignored = true,
        layout = {
          preset = "sidebar",
          width = 50,
          min_width = 50,
          layout = {
            position = "right",
            width = 50,
            min_width = 50,
          },
        },
        win = {
          list = {
            keys = {
              ["<C-h>"] = nil,
              ["<C-j>"] = nil,
              ["<C-k>"] = nil,
              ["<C-l>"] = nil,
            },
          },
        },
      },
      buffers = {
        current = false,
        sort_lastused = true,
        layout = {
          preset = "ivy",
          layout = {
            height = 0.5,
          },
        },
      },
      diagnostics = {
        layout = {
          preset = "select",
          layout = {
            width = 0.8,
            min_width = 80,
          },
        },
      },
      diagnostics_buffer = {
        layout = {
          preset = "select",
          layout = {
            width = 0.8,
            min_width = 80,
          },
        },
      },
    },
  },

  chunk = { enabled = true },
  notifier = { enabled = true },
  bigfile = { enabled = true },
  animate = { enabled = true },
  bufdelete = { enabled = true },
  debug = { enabled = true },
  git = { enabled = true },
  gitbrowse = { enabled = true },
  lazygit = { enabled = true },
  quickfile = { enabled = true },
  input = { enabled = true },
  rename = { enabled = true },
  scroll = { enabled = true },
  statuscolumn = { enabled = true },
  toggle = { enabled = true },
  words = { enabled = true },
}
