local lualine = require "lualine"

-- Function to get the number of open buffers using the :ls command
local function get_buffer_count()
  local buffers = vim.fn.execute "ls"
  local count = 0

  -- Match only lines that represent buffers, typically starting with a number followed by a space
  for line in string.gmatch(buffers, "[^\r\n]+") do
    if string.match(line, "^%s*%d+") then
      count = count + 1
    end
  end

  return " " .. count
end

lualine.setup {
  options = {
    theme = "catppuccin-nvim",
    globalstatus = true,
    section_separators = { left = "", right = "" },
    disabled_filetypes = { winbar = { "NvimTree", "alpha", "snacks_explorer", "snacks_picker_list" } },
  },

  sections = {
    lualine_a = { "mode" },
    lualine_b = { "location", "filesize" },
    lualine_c = {

      {
        "filename",
        file_status = true,
        newfile_status = true,
        path = 1,
      },
      "diagnostics",
    },

    lualine_x = { "lsp_status" },
    lualine_y = { "encoding" },
    lualine_z = { get_buffer_count },
  },
}
