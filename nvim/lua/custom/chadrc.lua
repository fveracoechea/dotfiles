---@type ChadrcConfig
local M = {}

M.ui = { theme = 'catppuccin', telescope = { style = "bordered" } }
M.plugins = "custom.plugins"
M.mappings = require "custom.mappings"

return M
