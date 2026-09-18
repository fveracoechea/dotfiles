-- Fixture: expected canonical bind records, hand-transcribed from the live
-- baseline capture (docs/research/hyprland-live-baseline/hyprctl/binds.json)
-- and from the structural fixture cases. This file is the independent
-- expected side: it is written against the capture, not against
-- bindings-module.lua, so a mistake in the module fails the comparison.

local M = {}

local function record(spec)
  return {
    modmask = spec.mod,
    key = spec.key,
    keycode = spec.keycode or 0,
    submap = spec.submap or "",
    catch_all = spec.catch_all or false,
    description = spec.description or "",
    has_description = spec.description ~= nil,
    dispatcher = spec.dispatcher,
    arg = spec.arg or "",
    flags = {
      locked = false,
      mouse = spec.mouse or false,
      release = false,
      ["repeat"] = false,
      longPress = false,
      non_consuming = false,
      auto_consuming = false,
    },
  }
end

M.baseline = {
  record { mod = 64, key = "J", description = "Toggle window split", dispatcher = "layoutmsg", arg = "togglesplit," },
  record { mod = 64, key = "T", description = "Toggle window floating/tiling", dispatcher = "togglefloating" },
  record { mod = 68, key = "F", description = "Tiled full screen", dispatcher = "fullscreenstate", arg = "0 2" },
  record { mod = 72, key = "F", description = "Full width", dispatcher = "fullscreen", arg = "1" },
  record { mod = 64, key = "J", description = "Move window focus D", dispatcher = "movefocus", arg = "d" },
  record { mod = 64, key = "1", description = "Switch to workspace 1", dispatcher = "workspace", arg = "1" },
  record { mod = 9, key = "mouse:272", mouse = true, dispatcher = "mouse", arg = "movewindow" },
}

M.structural = {
  record { mod = 64, key = "J", submap = "resize", dispatcher = "resizeactive", arg = "0 100" },
  record { mod = 0, key = "code:36", keycode = 36, submap = "resize", dispatcher = "killactive" },
  record {
    mod = 0,
    key = "",
    submap = "resize",
    catch_all = true,
    description = "Pass to resize",
    dispatcher = "movefocus",
    arg = "l",
  },
}

return M
