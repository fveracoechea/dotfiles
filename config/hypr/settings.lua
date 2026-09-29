local colors = dofile "@catppuccinMocha@"

hl.monitor {
  output = "DP-1",
  mode = "preferred",
  position = "auto",
  scale = "auto",
  bitdepth = 10,
  cm = "auto",
}
hl.monitor { output = "HDMI-A-1", disabled = true }

hl.config {
  cursor = { enable_hyprcursor = false },
  misc = { vrr = 2, animate_manual_resizes = true, animate_mouse_windowdragging = true },
  general = {
    layout = "dwindle",
    border_size = 2,
    resize_on_border = true,
    gaps_in = 8,
    gaps_out = { top = 10, right = 16, bottom = 16, left = 16 },
    ["col.active_border"] = { colors = { colors.blue, colors.flamingo }, angle = 90 },
    ["col.inactive_border"] = colors.surface2,
  },
  layout = { single_window_aspect_ratio = "16 9" },
  dwindle = { preserve_split = true, force_split = 2 },
  decoration = { rounding = 4, blur = { enabled = true } },
  master = { allow_small_split = true, mfact = 0.32, new_on_top = false },
  binds = { drag_threshold = 10, allow_workspace_cycles = true },
  ecosystem = { no_update_news = true },
  xwayland = { force_zero_scaling = true },
}

for workspace = 1, 5 do
  hl.workspace_rule { workspace = tostring(workspace), persistent = true }
end

hl.env("BROWSER", "google-chrome-stable")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XCURSOR_SIZE", "38")
hl.env("HYPRCURSOR_SIZE", "38")
