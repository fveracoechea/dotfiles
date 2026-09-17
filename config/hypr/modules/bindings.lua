local bindings = {}

function bindings.apply(data)
  local function bind(keys, description, dispatcher)
    hl.bind(keys, dispatcher, { description = description })
  end

  bind("SUPER + J", "Toggle window split", hl.dsp.layout "togglesplit,")
  bind("SUPER + T", "Toggle window floating/tiling", hl.dsp.window.float())
  bind("SUPER + F", "Full screen", hl.dsp.window.fullscreen())
  bind("SUPER + CTRL + F", "Tiled full screen", hl.dsp.window.fullscreen_state { internal = 0, client = 2 })
  bind("SUPER + ALT + F", "Full width", hl.dsp.window.fullscreen { mode = "maximized" })
  bind("SUPER + W", "Close window", hl.dsp.window.close())

  for _, direction in ipairs { { "K", "u" }, { "J", "d" }, { "L", "r" }, { "H", "l" } } do
    bind(
      "SUPER + " .. direction[1],
      "Move window focus " .. direction[2]:upper(),
      hl.dsp.focus { direction = direction[2] }
    )
  end
  for _, size in ipairs { { "K", 0, -100 }, { "J", 0, 100 }, { "L", 100, 0 }, { "H", -100, 0 } } do
    bind(
      "SUPER + CTRL + " .. size[1],
      "Resize active window " .. size[1],
      hl.dsp.window.resize { x = size[2], y = size[3], relative = true }
    )
  end

  bind("SUPER + P", "Pseudo window", hl.dsp.window.pseudo())
  bind("SUPER + CTRL + P", "Toggle All Pseudo window", hl.dsp.exec_cmd "hyprctl dispatch workspaceopt allpseudo")
  bind("SUPER + TAB", "Next workspace", hl.dsp.focus { workspace = "e+1" })
  bind("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus { workspace = "e-1" })
  bind("SUPER + CTRL + TAB", "Former workspace", hl.dsp.focus { workspace = "previous" })
  bind("SUPER + G", "Toggle window grouping", hl.dsp.group.toggle())
  bind("SUPER + ALT + G", "Move active window out of group", hl.dsp.window.move { out_of_group = true })

  local cache = data.paths.fuzzelCache
  if not cache:match "^[%w_./%-]+$" then
    cache = "'" .. cache:gsub("'", "'\\''") .. "'"
  end
  for _, app in ipairs {
    { "B", "google-chrome-stable" },
    { "S", "ghostty" },
    { "A", "fuzzel --cache " .. cache },
    { "O", "handy --toggle-transcription" },
  } do
    bind("SUPER + " .. app[1], "Open " .. app[2], hl.dsp.exec_cmd(app[2]))
  end

  bind("SUPER + C", "Copy", hl.dsp.send_shortcut { mods = "CTRL", key = "INSERT", window = "activewindow" })
  bind("SUPER + V", "Paste", hl.dsp.send_shortcut { mods = "SHIFT", key = "INSERT", window = "activewindow" })
  for workspace = 1, 9 do
    local name = tostring(workspace)
    bind("SUPER + " .. name, "Switch to workspace " .. name, hl.dsp.focus { workspace = name })
  end
  for workspace = 1, 9 do
    local name = tostring(workspace)
    bind(
      "SUPER + SHIFT + " .. name,
      "Move active window to workspace " .. name,
      hl.dsp.window.move { workspace = name }
    )
  end
  hl.bind("SHIFT + ALT + mouse:272", hl.dsp.window.drag())
end

return bindings
