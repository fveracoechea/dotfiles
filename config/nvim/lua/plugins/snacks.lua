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
    layout = { preset = "ivy", layout = { height = 0.75 } },
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
      },
      buffers = {
        current = false,
        sort_lastused = true,
      },
    },
  },

  notifier = { enabled = true },
  bigfile = { enabled = true },
  animate = { enabled = true },
  bufdelete = { enabled = true },
  debug = { enabled = true },
  gh = { enabled = true },
  git = { enabled = true },
  gitbrowse = { enabled = true },
  keymap = { enabled = true },
  image = { enabled = true },
  lazygit = { enabled = true },
  quickfile = { enabled = true },
  input = { enabled = true },
  rename = { enabled = true },
  scroll = { enabled = true },
  statuscolumn = { enabled = true },
  toggle = { enabled = true },
  words = { enabled = true },
}
