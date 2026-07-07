require("bufferline").setup {
  highlights = require("catppuccin.special.bufferline").get_theme(),
  options = {
    mode = "buffers",
    sort_by = "recently_used",
    numbers = "ordinal",
    diagnostics_update_in_insert = false,
    show_buffer_close_icons = true,
    show_close_icon = false,
    close_icon = "",
    buffer_close_icon = "",
    separator_style = "thin",
    always_show_bufferline = true,
    offsets = {
      {
        filetype = "snacks_picker_list",
        text = "Explorer",
        highlight = "Directory",
        separator = true,
      },
    },
  },
}
