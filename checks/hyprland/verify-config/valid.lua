-- Parser fixture: a small but representative Lua config for the pinned
-- Hyprland 0.55.4 parser gate (Hyprland --verify-config). Every call shape
-- here is verified against the v0.55.4 source; see checks/hyprland/api.md.

hl.config {
  general = {
    gaps_in = 10,
    gaps_out = { top = 10, right = 18, bottom = 18, left = 18 },
    layout = "dwindle",
    ["col.active_border"] = { colors = { "rgb(89b4fa)", "rgb(f2cdcd)" }, angle = 90 },
    ["col.inactive_border"] = "rgb(585b70)",
  },
  dwindle = { preserve_split = true },
}

hl.env("XDG_SESSION_TYPE", "wayland")

hl.monitor { output = "DP-1" }
hl.monitor { output = "HDMI-A-1", disabled = true }

hl.window_rule { match = { class = "mpv" }, float = true }

hl.workspace_rule { workspace = "1", persistent = true }

hl.bind("SUPER + J", hl.dsp.layout "togglesplit,", { description = "Toggle window split" })
hl.bind(
  "SUPER + CTRL + F",
  hl.dsp.window.fullscreen_state { internal = 0, client = 2 },
  { description = "Tiled full screen" }
)
hl.bind("SUPER + 1", hl.dsp.focus { workspace = "1" }, { description = "Switch to workspace 1" })
hl.bind("SUPER + TAB", hl.dsp.focus { workspace = "e+1" }, { description = "Next workspace" })
hl.bind("SUPER + W", hl.dsp.window.close(), { description = "Close window" })
hl.bind("SUPER + Q", function() end)

hl.on("hyprland.start", function() end)

hl.define_submap("resize", function()
  hl.bind("SUPER + J", hl.dsp.window.resize { x = 0, y = 100, relative = true })
  hl.bind("catchall", hl.dsp.focus { direction = "l" })
end)
