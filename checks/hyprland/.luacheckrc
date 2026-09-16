cache = false
std = "lua54"

-- The Hyprland Lua world: `hl` is the configuration global, `arg` comes from
-- the standalone interpreter running the gates. Luacheck has no 5.5 mode, so
-- lua54 is the closest lint target; Lua 5.5 syntax is checked with luac5.5.
globals = {
  "hl",
  "arg",
}

ignore = {
  "112",
  "122",
  "212/_.*",
  "542",
  "631",
}

-- The decoder retains upstream style; strict grammar has direct regression tests.
exclude_files = {
  "**/lib/json.lua",
}
