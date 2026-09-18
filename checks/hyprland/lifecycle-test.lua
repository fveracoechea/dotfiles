-- Called by semantic-test.lua so the existing fixture check covers lifecycle parity.
return function(here, root, report)
  local ok, capture = pcall(require, "capture")
  if not ok then
    report(false, "controlled lifecycle capture exists")
    return
  end
  local records = require "records"
  local f = assert(io.open(root .. "/docs/research/hyprland-live-baseline/generated/hyprland.conf"))
  local conf = f:read "*a"
  f:close()
  local source = [[
    hl.on("hyprland.start", function()
      hl.exec_cmd("/nix/store/<hash>/bin/dbus-update-activation-environment --systemd DISPLAY HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE && systemctl --user stop hyprland-session.target && systemctl --user start hyprland-session.target")
    end)
    hl.on("hyprland.shutdown", function()
      os.execute("systemctl --user stop hyprland-session.target && sleep 0.1")
    end)
    require("entry")
  ]]
  local function run(text)
    return capture.run(text, here .. "/fixtures/lifecycle")
  end
  local state = run(source)
  report(#records.diff_startup(state, conf) == 0, "HM-shaped entry matches baseline with approved shutdown exception")
  for _, command in ipairs {
    "systemctl --user stop hyprland-session.target",
    "systemctl --user stop hyprland-session.target && sleep 0.2",
    "systemctl --user stop hyprland-session.target ; sleep 0.1",
    "systemctl --user stop other.target && sleep 0.1",
    "systemctl --user stop hyprland-session.target && sleep 0.1 && true",
    "sleep 0.1 && systemctl --user stop hyprland-session.target",
  } do
    local mutation = source:gsub("systemctl %-%-user stop hyprland%-session%.target && sleep 0%.1", function()
      return command
    end)
    report(#records.diff_startup(run(mutation), conf) > 0, "unapproved shutdown command rejected: " .. command)
  end
  local changed_baseline = conf:gsub(
    "exec%-shutdown = systemctl %-%-user stop hyprland%-session%.target",
    "exec-shutdown = systemctl --user stop other.target"
  )
  report(#records.diff_startup(state, changed_baseline) > 0, "shutdown exception requires the exact captured command")
  local extra_shutdown = source
    .. '\nhl.on("hyprland.shutdown", function() os.execute("systemctl --user stop hyprland-session.target && sleep 0.1") end)'
  report(#records.diff_startup(run(extra_shutdown), conf) > 0, "duplicate approved shutdown command rejected")
  local changed_startup = run(source)
  changed_startup.lifecycle["hyprland.start"][2] = "ultrashell && sleep 0.1"
  report(#records.diff_startup(changed_startup, conf) > 0, "shutdown exception does not strip startup suffixes")
  local supported = run [[
    hl.config { general = { layout = "dwindle" } }
    hl.bind("SUPER + J", hl.dsp.window.close())
  ]]
  report(#supported.options == 1 and #supported.binds == 1, "supported config and dispatcher lookups still work")
  for _, text in ipairs {
    'hl.on("hyprland.start", function() pcall(hl.dispatch, hl.dsp.exec_cmd("extra")) end)',
    'assert(not pcall(function() hl.dispatch(hl.dsp.exec_cmd("extra")) end))',
    'hl.on("hyprland.start", function() assert(not pcall(function() hl.dispatch(hl.dsp.exec_cmd("extra")) end)) end)',
  } do
    local captured, err = pcall(run, text)
    report(
      not captured and tostring(err):find("unsupported hl operation dispatch", 1, true) ~= nil,
      "unsupported hl lookup rejects capture even through pcall"
    )
  end
  for _, mutation in ipairs {
    'require("entry")\n' .. source,
    'hl.on("hyprland.start", function() end)\nhl.on("hyprland.shutdown", function() end)',
    source:gsub('require%("entry"%)', ""),
    source:gsub("systemctl %-%-user stop hyprland%-session%.target && sleep 0%.1", "wrong-command"),
    source .. '\nhl.exec_cmd("unexpected-config-spawn")',
    source .. '\nhl.on("window.open", function() end)',
    source .. '\nhl.on("hyprland.start", function() hl.exec_cmd("extra") end)',
  } do
    report(#records.diff_startup(run(mutation), conf) > 0, "changed lifecycle commands or events fail parity")
  end
  local real_execute, calls = os.execute, 0
  os.execute = function()
    calls = calls + 1
    error "real os.execute reached"
  end
  local captured, result = pcall(
    run,
    [[
    hl.on("hyprland.start", function() os.execute("arbitrary command must not execute") end)
  ]]
  )
  os.execute = real_execute
  report(
    captured and calls == 0 and result.lifecycle["hyprland.start"][1] == "arbitrary command must not execute",
    "os.execute callback is recorded without invoking the host"
  )
  for _, text in ipairs {
    'io.popen("anything")',
    'io.open("/tmp/capture-must-not-write", "w")',
    'require("ffi")',
    'require("../escape")',
    'package.loadlib("anything", "anything")',
    'hl.on("hyprland.start", function() hl.env("X", "Y") end)',
    'hl.exec_cmd("cmd", {float=true})',
    'hl.env("X", "Y", true)',
    'pcall(function() io.popen("anything") end)',
    'pcall(function() hl.env("X", "Y", true) end)',
  } do
    report(not pcall(run, text), "unsupported side effect rejected: " .. text)
  end
  local executable = "/approved/dbus-update-activation-environment"
  local changed = source:gsub("/nix/store/<hash>/bin/dbus%-update%-activation%-environment", executable)
  report(
    #records.diff_startup(run(changed), conf, executable) == 0,
    "only declared dbus executable substitution accepted"
  )
  report(#records.diff_startup(run(changed), conf, "/other/dbus") > 0, "wrong dbus executable fails parity")
end
