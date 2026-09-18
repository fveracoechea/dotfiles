-- Fixture: a bindings module in the exact shape the port ticket will ship.
-- It mirrors a subset of the live baseline capture (chosen to cover the hard
-- cases) plus the structural cases the baseline cannot show (submap, keycode,
-- catchall). The expected records for the baseline subset are transcribed
-- independently from docs/research/hyprland-live-baseline/hyprctl/binds.json
-- in expected.lua; this module is the producer side.

local M = {}

-- opts (optional): { skip = n } drops the nth bind (mutation tests use this
-- to prove the comparator catches missing records), { extra = fn } applies an
-- extra function after the standard binds.
function M.apply(hl, opts)
  local n = 0
  local function bind(...)
    n = n + 1
    if not (opts and opts.skip == n) then
      hl.bind(...)
    end
  end

  -- binds.json #1: bindd=SUPER, J, Toggle window split, layoutmsg, togglesplit,
  bind("SUPER + J", hl.dsp.layout "togglesplit,", { description = "Toggle window split" })
  -- binds.json #2
  bind("SUPER + T", hl.dsp.window.float(), { description = "Toggle window floating/tiling" })
  -- binds.json #4: bindd=SUPER CTRL, F, Tiled full screen, fullscreenstate, 0 2
  bind(
    "SUPER + CTRL + F",
    hl.dsp.window.fullscreen_state { internal = 0, client = 2 },
    { description = "Tiled full screen" }
  )
  -- binds.json #5: bindd=SUPER ALT, F, Full width, fullscreen, 1
  bind("SUPER + ALT + F", hl.dsp.window.fullscreen { mode = "maximized" }, { description = "Full width" })
  -- binds.json #10: the duplicate SUPER+J with a different dispatcher
  bind("SUPER + J", hl.dsp.focus { direction = "d" }, { description = "Move window focus D" })
  -- binds.json #30
  bind("SUPER + 1", hl.dsp.focus { workspace = "1" }, { description = "Switch to workspace 1" })
  -- binds.json #46: bindm=SHIFT_ALT, mouse:272, movewindow
  bind("SHIFT + ALT + mouse:272", hl.dsp.window.drag())

  -- Structural cases beyond the baseline: submap with a duplicate-key bind,
  -- a keycode bind, and a catchall bind (legal only inside a submap).
  hl.define_submap("resize", function()
    bind("SUPER + J", hl.dsp.window.resize { x = 0, y = 100, relative = true })
    bind("code:36", hl.dsp.window.close())
    bind("catchall", hl.dsp.focus { direction = "l" }, { description = "Pass to resize" })
  end)

  if opts and opts.extra then
    opts.extra(hl)
  end
end

return M
