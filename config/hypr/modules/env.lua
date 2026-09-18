local env = {}

function env.apply()
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

  hl.config {
    ecosystem = { no_update_news = true },
    xwayland = { force_zero_scaling = true },
  }
end

return env
