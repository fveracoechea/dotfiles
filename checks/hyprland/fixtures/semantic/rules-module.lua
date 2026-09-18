-- Fixture: an env/rules/startup module in the shape the port ticket will
-- ship, mirroring the captured hyprlang config
-- (docs/research/hyprland-live-baseline/generated/hyprland.conf).
--
-- env entries compare byte-level against the captured env= lines. Monitors
-- and window rules use the structured API verified from the pinned source
-- (api.md); the comparators pair them with the captured lines positionally
-- and cross-check the fields, while the rendered-string equivalence is
-- asserted at the live session gate.

local M = {}

function M.apply(hl)
  -- captured env= lines, in file order
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

  -- captured monitor= lines; typed fields from MONITOR_FIELDS in
  -- LuaBindingsConfigRules.cpp. Every field the legacy line states must be
  -- explicit here; the comparators default both sides to the factory
  -- defaults for absent fields.
  hl.monitor {
    output = "DP-1",
    mode = "5120x1440@119.98Hz",
    position = "auto",
    scale = "auto",
    bitdepth = 8,
    cm = "auto",
  }
  hl.monitor {
    output = "HDMI-A-1",
    disabled = true,
  }

  -- captured workspace= lines (persistent workspaces 1-5)
  hl.workspace_rule { workspace = "1", persistent = true }
  hl.workspace_rule { workspace = "2", persistent = true }
  hl.workspace_rule { workspace = "3", persistent = true }
  hl.workspace_rule { workspace = "4", persistent = true }
  hl.workspace_rule { workspace = "5", persistent = true }

  -- captured windowrule= lines; effect and match names from
  -- WINDOW_RULE_EFFECT_DESCS (LuaBindingsInternal.hpp) and MATCH_PROP_STRINGS
  -- (desktop/rule/Rule.cpp)
  hl.window_rule { match = { tag = "floating-window" }, float = true }
  hl.window_rule { match = { tag = "floating-window" }, center = true }
  hl.window_rule { match = { tag = "floating-window" }, size = "1024 768" }
  hl.window_rule {
    match = { class = "(blueberry.py|Impala|Wiremix|org.gnome.NautilusPreviewer|com.gabm.satty|TUI.float|imv|mpv)" },
    tag = "+floating-window",
  }
  hl.window_rule {
    match = {
      class = "(xdg-desktop-portal-gtk|DesktopEditors|org.gnome.Nautilus)",
      title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)",
    },
    tag = "+floating-window",
  }
  hl.window_rule { match = { class = "org.gnome.Calculator" }, float = true }
  hl.window_rule { match = { fullscreen = "1" }, border_size = 0 }
  hl.window_rule { match = { class = ".*" }, idle_inhibit = "fullscreen" }
  hl.window_rule { match = { class = ".*" }, suppress_event = "maximize" }

  -- The Lua seam has no exec-once API; the port expresses startup through
  -- hl.on("hyprland.start"), which the HM entry also uses for the systemd
  -- session hooks. Startup parity asserts the event order.
  hl.on("hyprland.start", function() end)
  hl.on("hyprland.shutdown", function() end)
end

return M
