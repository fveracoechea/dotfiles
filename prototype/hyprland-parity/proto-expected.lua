-- PROTOTYPE for issue 32. Throwaway comparator, not the production harness.
--
-- Fixed expected bind records, hand-copied from the live baseline at
-- docs/research/hyprland-live-baseline/hyprctl/binds.json (captured from the
-- running Hyprland 0.55.4 session, issue 35). This is live compositor
-- evidence, the parity oracle. Nothing here is derived from guessed Lua
-- calls: the Lua-call-to-record producer is a marked evidence gap.
--
-- Each entry: { index = 1-based position in the live binds.json array,
--               record = canonical record }
--
-- Canonical record shape (one side lives in binds.json, the other would be
-- produced by the stub-exec call log):
--   modmask      integer, Hyprland mod bits (SHIFT 1, CAPS 2, CTRL 4,
--                ALT 8, MOD2 16, MOD3 32, SUPER 64, MOD5 128)
--   flags        exactly the binds.json booleans
--   key          string, verbatim (includes "mouse:272")
--   description  string ("" when has_description is false)
--   dispatcher   string, internal dispatcher name as hyprctl reports it
--   arg          string, verbatim including trailing commas

return {
  { index = 1, record = {
      modmask = 64, key = "J", keycode = 0,
      submap = "", catch_all = false,
      description = "Toggle window split",
      dispatcher = "layoutmsg", arg = "togglesplit,",
      flags = { locked = false, mouse = false, release = false,
        [ "repeat" ] = false, longPress = false, non_consuming = false,
        auto_consuming = false, has_description = true },
  } },
  { index = 2, record = {
      modmask = 64, key = "T", keycode = 0,
      submap = "", catch_all = false,
      description = "Toggle window floating/tiling",
      dispatcher = "togglefloating", arg = "",
      flags = { locked = false, mouse = false, release = false,
        [ "repeat" ] = false, longPress = false, non_consuming = false,
        auto_consuming = false, has_description = true },
  } },
  { index = 4, record = {
      modmask = 68, key = "F", keycode = 0,
      submap = "", catch_all = false,
      description = "Tiled full screen",
      dispatcher = "fullscreenstate", arg = "0 2",
      flags = { locked = false, mouse = false, release = false,
        [ "repeat" ] = false, longPress = false, non_consuming = false,
        auto_consuming = false, has_description = true },
  } },
  { index = 8, record = {
      modmask = 64, key = "J", keycode = 0,
      submap = "", catch_all = false,
      description = "Move window focus D",
      dispatcher = "movefocus", arg = "d",
      flags = { locked = false, mouse = false, release = false,
        [ "repeat" ] = false, longPress = false, non_consuming = false,
        auto_consuming = false, has_description = true },
  } },
  { index = 26, record = {
      modmask = 64, key = "C", keycode = 0,
      submap = "", catch_all = false,
      description = "Copy",
      dispatcher = "sendshortcut", arg = "CTRL, INSERT, activewindow",
      flags = { locked = false, mouse = false, release = false,
        [ "repeat" ] = false, longPress = false, non_consuming = false,
        auto_consuming = false, has_description = true },
  } },
  { index = 46, record = {
      modmask = 9, key = "mouse:272", keycode = 0,
      submap = "", catch_all = false,
      description = "",
      dispatcher = "mouse", arg = "movewindow",
      flags = { locked = false, mouse = true, release = false,
        [ "repeat" ] = false, longPress = false, non_consuming = false,
        auto_consuming = false, has_description = false },
  } },
}
