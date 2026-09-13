-- Semantic parity tests, fixture mode. Run under Lua 5.5:
--
--   lua semantic-test.lua <repo-root>
--
-- Pipeline: fixture module -> stub records -> canonical records ->
-- positional diff against the hand-transcribed expected fixture, then
-- negative mutations that the diff must each detect. A comparator that
-- misses any mutation would reduce parity to a count.

local function script_dir()
  local src = debug.getinfo(1, "S").source:sub(2)
  return src:match "^(.*)/" or "."
end

local here = script_dir()
local root = (arg and arg[1]) or here .. "/../.."
package.path = here .. "/?.lua;" .. here .. "/lib/?.lua;" .. package.path

local records = require "records"
local stub = require "hl-stub"
local bindings_module = dofile(here .. "/fixtures/semantic/bindings-module.lua")
local expected = dofile(here .. "/fixtures/semantic/expected.lua")

local failures = 0
local checks = 0

local function report(ok, label, detail)
  checks = checks + 1
  if ok then
    print("  ok   " .. label)
  else
    failures = failures + 1
    print("  FAIL " .. label)
    for _, line in ipairs(detail or {}) do
      print("       " .. line)
    end
  end
end

local all_expected = {}
for _, r in ipairs(expected.baseline) do
  table.insert(all_expected, r)
end
for _, r in ipairs(expected.structural) do
  table.insert(all_expected, r)
end

-- Produce canonical records the same way the production gate will.
local function canonicalize(state)
  local out = {}
  for _, bind in ipairs(state.binds) do
    local legacy, err = records.legacy_dispatcher(bind.dispatcher)
    if not legacy then
      error("canonicalize: " .. tostring(err), 2)
    end
    local record = {
      modmask = bind.modmask,
      key = bind.key,
      keycode = bind.keycode,
      submap = bind.submap,
      catch_all = bind.catch_all,
      description = bind.description,
      has_description = bind.has_description,
      dispatcher = legacy.dispatcher,
      arg = legacy.arg,
      flags = bind.flags,
    }
    out[#out + 1] = records.normalize_mouse_flag(record)
  end
  return out
end

local function run_produced(opts)
  local state = stub.run {
    function(hl)
      bindings_module.apply(hl, opts)
    end,
  }
  return canonicalize(state)
end

local function diff(produced)
  return records.diff_ordered(all_expected, produced, records.bind_eq, "binds")
end

local function mutation_detected(label, opts)
  local produced = run_produced(opts)
  local d = diff(produced)
  report(#d > 0, label, #d == 0 and { "mutation was NOT detected" } or nil)
end

print "== stub capture =="
do
  local state = stub.run {
    function(hl)
      bindings_module.apply(hl)
    end,
  }
  report(#state.binds == 10, "stub captured 10 binds (" .. #state.binds .. ")")
  report(state.binds[8].submap == "resize", "submap recorded on binds inside define_submap")
  report(state.binds[10].catch_all == true, "catch_all recorded")
  report(state.binds[9].keycode == 36, "keycode recorded from code:36")
end

print "== positive: fixture module vs expected fixture =="
do
  local produced = run_produced()
  local d = diff(produced)
  local detail = {}
  for i, line in ipairs(d) do
    if i > 8 then
      table.insert(detail, "...")
      break
    end
    table.insert(detail, line)
    local pos = tonumber(line:match "position (%d+)" or line:match "record (%d+)")
    if pos and all_expected[pos] and produced[pos] then
      table.insert(detail, "  expected: " .. records.describe_bind(all_expected[pos]))
      table.insert(detail, "  produced: " .. records.describe_bind(produced[pos]))
    end
  end
  report(#d == 0, "ordered positional match of all 10 records", detail)
end

print "== negative mutations (each must be detected) =="

-- order swap of the two duplicate SUPER+J binds: same records, opposite order
do
  local state = stub.run {
    function(hl)
      bindings_module.apply(hl)
    end,
  }
  state.binds[1], state.binds[5] = state.binds[5], state.binds[1]
  local d = diff(canonicalize(state))
  report(#d > 0, "order swap of the two SUPER+J binds detected")
end

mutation_detected("arg change: fullscreenstate 0 2 -> 0 1", {
  skip = 3,
  extra = function(hl)
    hl.bind(
      "SUPER + CTRL + F",
      hl.dsp.window.fullscreen_state { internal = 0, client = 1 },
      { description = "Tiled full screen" }
    )
  end,
})

mutation_detected("flag flip: locked=true on the workspace bind", {
  skip = 6,
  extra = function(hl)
    hl.bind("SUPER + 1", hl.dsp.focus { workspace = "1" }, { description = "Switch to workspace 1", locked = true })
  end,
})

mutation_detected("description change on the mouse bind", {
  skip = 7,
  extra = function(hl)
    hl.bind("SHIFT + ALT + mouse:272", hl.dsp.window.drag(), { description = "Drag window" })
  end,
})

mutation_detected("missing record: layoutmsg bind dropped", { skip = 1 })

mutation_detected("extra record: unexpected SUPER+Q bind", {
  extra = function(hl)
    hl.bind("SUPER + Q", hl.dsp.window.close())
  end,
})

mutation_detected("trailing comma dropped from layoutmsg arg", {
  skip = 1,
  extra = function(hl)
    hl.bind("SUPER + J", hl.dsp.layout "togglesplit", { description = "Toggle window split" })
  end,
})

mutation_detected("bind moved out of submap 'resize'", {
  skip = 8,
  extra = function(hl)
    hl.bind("SUPER + J", hl.dsp.window.resize { x = 0, y = 100, relative = true })
  end,
})

mutation_detected("keycode 59 recorded instead of code:36", {
  skip = 9,
  extra = function(hl)
    hl.bind("code:59", hl.dsp.window.close())
  end,
})

do
  -- The stub mirrors hlBind's placement rule; the real parser owns the rest
  -- of the key grammar.
  local ok, err = pcall(function()
    stub.run {
      function(hl)
        hl.bind("catchall", hl.dsp.window.close())
      end,
    }
  end)
  report(
    not ok and tostring(err):find("catchall", 1, true) ~= nil,
    "catchall outside a submap is rejected by the stub",
    { tostring(err) }
  )
end

print "== stub strictness =="
do
  local ok = pcall(function()
    stub.run {
      function(hl)
        hl.bind("J + SUPER", hl.dsp.window.close())
      end,
    }
  end)
  report(not ok, "modifiers after the key are rejected")
end
do
  local ok = pcall(function()
    stub.run {
      function(hl)
        hl.bind("SUPER + J", hl.dsp.nonsense())
      end,
    }
  end)
  report(not ok, "unknown dispatcher path is rejected")
end
do
  local ok = pcall(function()
    stub.run {
      function(hl)
        hl.bind("SUPER + J", "not-a-dispatcher")
      end,
    }
  end)
  report(not ok, "non-dispatcher argument is rejected")
end
do
  local ok = pcall(function()
    stub.run {
      function(hl)
        hl.on("hyprland.restart", function() end)
      end,
    }
  end)
  report(not ok, "unknown event name is rejected")
end

print "== typed options =="
do
  local state = stub.run {
    function(hl)
      hl.config {
        general = {
          layout = "dwindle",
          gaps_in = 10,
          gaps_out = { top = 10, right = 18, bottom = 18, left = 18 },
          ["col.active_border"] = { colors = { "rgb(89b4fa)", "rgb(f2cdcd)" }, angle = 90 },
          ["col.inactive_border"] = "rgb(585b70)",
        },
        dwindle = { preserve_split = true },
        master = { mfact = 0.32 },
        layout = { single_window_aspect_ratio = "16 9" },
      }
    end,
  }
  local keys = {}
  for _, opt in ipairs(state.options) do
    keys[opt.key] = true
  end
  report(
    keys["general.layout"] and keys["dwindle.preserve_split"] and keys["layout.single_window_aspect_ratio"],
    "nested config flattens to dotted paths"
  )
  local lua_options = state.options
  local baseline = {
    { option = "general:layout", str = "dwindle" },
    { option = "general:gaps_in", custom = "10 10 10 10" },
    { option = "general:gaps_out", custom = "10 18 18 18" },
    { option = "general:col.active_border", custom = "ff89b4fa fff2cdcd 90deg" },
    { option = "general:col.inactive_border", custom = "ff585b70 0deg" },
    { option = "master:mfact", float = 0.32 },
    { option = "dwindle:preserve_split", int = 1 },
    { option = "layout:single_window_aspect_ratio", vec2 = { 16, 9 } },
  }
  local d = records.diff_options(lua_options, baseline)
  report(#d == 0, "fixture options normalize to the baseline capture", d)
end
do
  local d = records.diff_options({
    { key = "general.layout", value = "master" },
  }, {
    { option = "general:layout", str = "dwindle" },
  })
  report(#d == 1, "changed option value detected", d)
end
do
  local d = records.diff_options({
    { key = "general.layout", value = "dwindle" },
    { key = "general.nope", value = 1 },
  }, {
    { option = "general:layout", str = "dwindle" },
  })
  report(#d == 1, "option outside the registry detected", d)
end
do
  local d = records.diff_options({
    { key = "general.layout", value = "dwindle" },
  }, {
    { option = "general:layout", str = "dwindle" },
    { option = "general:gaps_in", custom = "10 10 10 10" },
  })
  report(#d == 1, "missing option detected", d)
end

print "== baseline decode gate (Lua 5.5 + vendored decoder) =="
do
  local json = require "lib.json"
  local f = assert(io.open(root .. "/docs/research/hyprland-live-baseline/hyprctl/binds.json", "r"))
  local binds = json.decode(f:read "*a")
  f:close()
  report(#binds == 46, "baseline binds.json decodes to 46 records")
  local canonical = records.canonical_baseline_bind(binds[1])
  report(
    canonical.dispatcher == "layoutmsg" and canonical.arg == "togglesplit,",
    "baseline record #1 canonicalizes verbatim"
  )
end

print "== disk evidence: env, monitors, rules, startup =="
do
  local rules_module = dofile(here .. "/fixtures/semantic/rules-module.lua")
  local state = stub.run {
    function(hl)
      rules_module.apply(hl)
    end,
  }

  local f = assert(io.open(root .. "/docs/research/hyprland-live-baseline/generated/hyprland.conf", "r"))
  local conf = f:read "*a"
  f:close()

  local d = records.diff_env(state.env, records.conf_lines(conf, "env"))
  report(#d == 0, "env entries match the captured config byte for byte", d)

  d = records.diff_monitors(state.monitors, records.conf_lines(conf, "monitor"))
  report(#d == 0, "monitor records pair with the captured monitor= lines", d)

  d = records.diff_window_rules(state.window_rules, records.conf_lines(conf, "windowrule"))
  report(#d == 0, "window rule records match the captured windowrule= lines", d)

  local json = require "lib.json"
  local wf = assert(io.open(root .. "/docs/research/hyprland-live-baseline/hyprctl/workspacerules.json", "r"))
  local ws_rules = json.decode(wf:read "*a")
  wf:close()
  d = records.diff_workspace_rules(state.workspace_rules, ws_rules)
  report(#d == 0, "workspace rules match the live capture", d)

  d = {}
  if state.events[1] ~= "hyprland.start" or state.events[2] ~= "hyprland.shutdown" then
    table.insert(d, "event order: " .. table.concat(state.events, ", "))
  end
  report(#d == 0, "systemd lifecycle events recorded in order", d)

  -- a wrong monitor output must fail
  local bad_state = stub.run {
    function(hl)
      rules_module.apply(hl)
    end,
  }
  bad_state.monitors[1].output = "DP-2"
  d = records.diff_monitors(bad_state.monitors, records.conf_lines(conf, "monitor"))
  report(#d == 1, "changed monitor output detected", d)

  -- a changed match property must fail
  local bad_rules = stub.run {
    function(hl)
      rules_module.apply(hl)
    end,
  }
  bad_rules.window_rules[1].match.tag = "other-tag"
  d = records.diff_window_rules(bad_rules.window_rules, records.conf_lines(conf, "windowrule"))
  report(#d >= 1, "changed match property detected", d)
end

print "== strict dispatcher mapping rejections (no silent normalization) =="
local function mapping_rejected(label, path, args)
  local legacy, err = records.legacy_dispatcher { path = path, args = args }
  report(legacy == nil and type(err) == "string", label, { tostring(err) })
end

mapping_rejected("fullscreen action 'set' rejected", "window.fullscreen", { mode = "fullscreen", action = "set" })
mapping_rejected("fullscreen invalid mode rejected", "window.fullscreen", { mode = "nonsense" })
mapping_rejected(
  "fullscreen_state action 'toggle' rejected",
  "window.fullscreen_state",
  { internal = 0, client = 2, action = "toggle" }
)
mapping_rejected("fullscreen_state missing client rejected", "window.fullscreen_state", { internal = 0 })
mapping_rejected("resize without relative rejected", "window.resize", { x = 0, y = -100 })
mapping_rejected("window.move spatial form rejected", "window.move", { direction = "left" })
mapping_rejected("focus with monitor selector rejected", "focus", { monitor = "DP-1" })
mapping_rejected("focus with both direction and workspace rejected", "focus", { direction = "u", workspace = "1" })
mapping_rejected("send_shortcut without window rejected", "send_shortcut", { mods = "CTRL", key = "INSERT" })
mapping_rejected("float with unsupported field rejected", "window.float", { on = "enable" })

print "== monitor spec parity mutations =="
do
  local rules_module = dofile(here .. "/fixtures/semantic/rules-module.lua")
  local f = assert(io.open(root .. "/docs/research/hyprland-live-baseline/generated/hyprland.conf", "r"))
  local conf = f:read "*a"
  f:close()
  local conf_monitors = records.conf_lines(conf, "monitor")

  local function monitor_mutation_detected(label, mutate)
    local bad_state = stub.run {
      function(hl)
        rules_module.apply(hl)
      end,
    }
    mutate(bad_state.monitors)
    local d = records.diff_monitors(bad_state.monitors, conf_monitors)
    report(#d >= 1, label, #d == 0 and { "mutation was NOT detected" } or nil)
  end

  monitor_mutation_detected("disabled=false against 'HDMI-A-1, disable' detected", function(monitors)
    monitors[2].disabled = false
  end)
  monitor_mutation_detected("bitdepth 10 against 8 detected", function(monitors)
    monitors[1].bitdepth = 10
  end)
  monitor_mutation_detected("mode change detected", function(monitors)
    monitors[1].mode = "5120x1440@60Hz"
  end)
  monitor_mutation_detected("omitted non-default line field detected", function(monitors)
    monitors[1].cm = nil
  end)
  monitor_mutation_detected("unsupported monitor field detected", function(monitors)
    monitors[1].mirror = "DP-2"
  end)

  report(records.parse_monitor_spec "DP-1, preferred" ~= nil, "disable-less minimal spec parses")
  local spec, err = records.parse_monitor_spec "DP-1, 5120x1440@60Hz, auto, auto, warp, 1"
  report(spec == nil and err ~= nil, "unknown monitor key rejected", { tostring(err) })
end

print "== window rule two-way mutations =="
do
  local rules_module = dofile(here .. "/fixtures/semantic/rules-module.lua")
  local f = assert(io.open(root .. "/docs/research/hyprland-live-baseline/generated/hyprland.conf", "r"))
  local conf = f:read "*a"
  f:close()
  local conf_rules = records.conf_lines(conf, "windowrule")

  local function rule_mutation_detected(label, mutate)
    local bad_state = stub.run {
      function(hl)
        rules_module.apply(hl)
      end,
    }
    mutate(bad_state.window_rules)
    local d = records.diff_window_rules(bad_state.window_rules, conf_rules)
    report(#d >= 1, label, #d == 0 and { "mutation was NOT detected" } or nil)
  end

  rule_mutation_detected("disabled rule against generated line detected", function(rules)
    rules[1].enabled = false
  end)
  rule_mutation_detected("extra match property detected", function(rules)
    rules[1].match.class = "mpv"
  end)
  rule_mutation_detected("extra effect detected", function(rules)
    rules[1].center = true
  end)
  rule_mutation_detected("missing match property detected", function(rules)
    rules[1].match.tag = nil
  end)
  rule_mutation_detected("effect value change detected", function(rules)
    rules[3].size = "1024 769"
  end)
end

print(
  failures == 0 and "== semantic tests: all " .. checks .. " checks pass =="
    or "== semantic tests: " .. failures .. " failure(s) of " .. checks .. " =="
)
os.exit(failures == 0 and 0 or 1)
