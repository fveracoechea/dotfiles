-- Canonical records and comparison for the Hyprland Lua parity gate.
--
-- Sources of truth:
--   - bind record shape: hyprctl binds -j JSON, src/debug/HyprCtl.cpp at
--     Hyprland v0.55.4 (bindsRequest)
--   - mod bit values: src/devices/IKeyboard.hpp (HL_MODIFIER_*)
--   - dispatcher mappings: src/config/lua/bindings/LuaBindingsDispatchers.cpp
--     and src/config/legacy/DispatcherTranslator.cpp at v0.55.4, documented in
--     api.md next to this file
--   - option normalizers: the live capture in
--     docs/research/hyprland-live-baseline/hyprctl/options.json is the oracle
--     for what hyprctl getoption reports for each value the config sets

local records = {}

-- src/debug/HyprCtl.cpp bindsRequest JSON field order, minus the flags that
-- live in the flags sub-table. ["repeat"] is bracket-quoted: reserved word.
local FLAG_KEYS = { "locked", "mouse", "release", "repeat", "longPress", "non_consuming", "auto_consuming" }

function records.canonical_baseline_bind(entry)
  local flags = {}
  for _, k in ipairs(FLAG_KEYS) do
    flags[k] = entry[k]
  end
  return {
    modmask = entry.modmask,
    key = entry.key,
    keycode = entry.keycode,
    submap = entry.submap,
    catch_all = entry.catch_all,
    description = entry.description,
    has_description = entry.has_description,
    dispatcher = entry.dispatcher,
    arg = entry.arg,
    flags = flags,
  }
end

-- Source-verified divergence (api.md): the hyprlang path derives the mouse
-- flag from the bindm keyword (ConfigManager.cpp case 'm'), but the Lua
-- hl.bind path never assigns kb.mouse (LuaBindingsToplevel.cpp), so a live
-- binds -j of a Lua-config mouse bind reports "mouse": false. The gate
-- normalizes the flag from the key prefix on both sides and documents the
-- divergence; the live session gate re-checks it against reality.
function records.normalize_mouse_flag(record)
  record.flags.mouse = type(record.key) == "string" and record.key:sub(1, 6) == "mouse:"
  return record
end

-- Ordered, positional, two-way diff. expected and actual are lists of
-- comparable values with an eq function. Returns a list of failure strings.
function records.diff_ordered(expected, actual, eq, label)
  local failures = {}
  local n = math.max(#expected, #actual)
  for i = 1, n do
    local e, a = expected[i], actual[i]
    if e == nil then
      table.insert(failures, string.format("%s: extra record at position %d", label, i))
    elseif a == nil then
      table.insert(failures, string.format("%s: missing record at position %d", label, i))
    elseif not eq(e, a) then
      table.insert(failures, string.format("%s: record %d differs", label, i))
    end
  end
  return failures
end

function records.bind_eq(a, b)
  local fields =
    { "modmask", "key", "keycode", "submap", "catch_all", "description", "has_description", "dispatcher", "arg" }
  for _, f in ipairs(fields) do
    if a[f] ~= b[f] then
      return false, f
    end
  end
  for _, f in ipairs(FLAG_KEYS) do
    if a.flags[f] ~= b.flags[f] then
      return false, "flag " .. f
    end
  end
  return true
end

function records.describe_bind(r)
  return string.format(
    "mod=%d key=%s keycode=%d submap=%q catch_all=%s desc=%q dsp=%s arg=%q",
    r.modmask,
    r.key,
    r.keycode,
    r.submap,
    tostring(r.catch_all),
    r.description,
    r.dispatcher,
    r.arg
  )
end

-- ---------------------------------------------------------------------------
-- Dispatcher identity mapping: what a hl.dsp.* constructor call means in the
-- hyprctl binds -j vocabulary. Every entry is verified against the v0.55.4
-- source (see api.md); the stub refuses to build dispatchers outside this
-- list, so the port cannot invent call shapes.
-- ---------------------------------------------------------------------------

-- key: stub dispatcher path; value: how to rebuild the legacy (dispatcher,
-- arg) pair from the constructor arguments. Forms with no legacy arg
-- equivalent (fullscreen set/unset actions, window.move spatial forms, focus
-- monitor/window selectors) are rejected, not normalized away: the parity
-- gate compares against the legacy vocabulary, and an unmappable call must
-- fail loudly rather than pass by construction.
local function require_keys(args, names)
  for _, name in ipairs(names) do
    if args[name] == nil then
      return nil, "'" .. name .. "' is required"
    end
  end
  return true
end

local function reject_extra(args, allowed, label)
  for key in pairs(args) do
    if not allowed[key] then
      return nil,
        "unsupported field '"
          .. tostring(key)
          .. "' in "
          .. label
          .. " (no verified legacy equivalent; reject rather than guess)"
    end
  end
  return true
end

local DISPATCHER_TO_LEGACY = {
  ["window.close"] = function(args)
    local ok, err = reject_extra(args, {}, "window.close")
    if not ok then
      return nil, err
    end
    return "killactive", ""
  end,
  ["window.float"] = function(args)
    local ok, err = reject_extra(args, {}, "window.float")
    if not ok then
      return nil, err
    end
    return "togglefloating", ""
  end,
  ["window.fullscreen"] = function(args)
    local ok, err = reject_extra(args, { mode = true, action = true }, "window.fullscreen")
    if not ok then
      return nil, err
    end
    if args.action ~= nil and args.action ~= "toggle" then
      return nil,
        "window.fullscreen action '"
          .. tostring(args.action)
          .. "' has no legacy arg equivalent (legacy 'fullscreen N' is a toggle)"
    end
    local mode = args.mode or "fullscreen"
    if mode ~= "fullscreen" and mode ~= "maximized" then
      return nil, "invalid mode '" .. tostring(mode) .. "'"
    end
    return "fullscreen", mode == "maximized" and "1" or "0"
  end,
  ["window.fullscreen_state"] = function(args)
    local ok, err = require_keys(args, { "internal", "client" })
    if not ok then
      return nil, err
    end
    ok, err = reject_extra(args, { internal = true, client = true, action = true }, "window.fullscreen_state")
    if not ok then
      return nil, err
    end
    if args.action ~= nil and args.action ~= "set" then
      return nil,
        "window.fullscreen_state action '"
          .. tostring(args.action)
          .. "' has no legacy arg equivalent (legacy 'fullscreenstate I C' is a set)"
    end
    return "fullscreenstate", tostring(args.internal) .. " " .. tostring(args.client)
  end,
  ["window.pseudo"] = function(args)
    local ok, err = reject_extra(args, {}, "window.pseudo")
    if not ok then
      return nil, err
    end
    return "pseudo", ""
  end,
  ["window.resize"] = function(args)
    local ok, err = require_keys(args, { "x", "y" })
    if not ok then
      return nil, err
    end
    ok, err = reject_extra(args, { x = true, y = true, relative = true }, "window.resize")
    if not ok then
      return nil, err
    end
    if args.relative ~= true then
      return nil, "window.resize needs relative=true to mean resizeactive"
    end
    return "resizeactive", tostring(args.x) .. " " .. tostring(args.y)
  end,
  ["window.drag"] = function(args)
    local ok, err = reject_extra(args, {}, "window.drag")
    if not ok then
      return nil, err
    end
    return "mouse", "movewindow"
  end,
  ["window.move"] = function(args)
    if args.out_of_group ~= nil then
      local ok, err = reject_extra(args, { out_of_group = true }, "window.move")
      if not ok then
        return nil, err
      end
      if args.out_of_group ~= true then
        return nil, "out_of_group must be true"
      end
      return "moveoutofgroup", ""
    end
    local ok, err = reject_extra(args, { workspace = true, follow = true }, "window.move")
    if not ok then
      return nil, err
    end
    if args.workspace == nil then
      return nil, "window.move without workspace has no legacy arg form"
    end
    if args.follow == false then
      return "movetoworkspacesilent", tostring(args.workspace)
    end
    return "movetoworkspace", tostring(args.workspace)
  end,
  ["group.toggle"] = function(args)
    local ok, err = reject_extra(args, {}, "group.toggle")
    if not ok then
      return nil, err
    end
    return "togglegroup", ""
  end,
  ["focus"] = function(args)
    local ok, err = reject_extra(args, { direction = true, workspace = true }, "focus")
    if not ok then
      return nil, err
    end
    if args.direction and args.workspace then
      return nil, "focus with both direction and workspace is ambiguous"
    end
    if args.direction then
      return "movefocus", args.direction
    end
    if args.workspace then
      return "workspace", args.workspace
    end
    return nil, "focus without direction or workspace has no legacy arg form"
  end,
  ["exec_cmd"] = function(args)
    local ok, err = reject_extra(args, { [1] = true }, "exec_cmd")
    if not ok then
      return nil, err
    end
    return "exec", args[1]
  end,
  ["send_shortcut"] = function(args)
    local allowed, extra = reject_extra(args, { mods = true, key = true, window = true }, "send_shortcut")
    if not allowed then
      return nil, extra
    end
    local ok, err = require_keys(args, { "mods", "key", "window" })
    if not ok then
      return nil, err
    end
    return "sendshortcut", args.mods .. ", " .. args.key .. ", " .. args.window
  end,
  ["layout"] = function(args)
    local ok, err = reject_extra(args, { [1] = true }, "layout")
    if not ok then
      return nil, err
    end
    return "layoutmsg", args[1]
  end,
}

function records.legacy_dispatcher(dsp)
  local convert = DISPATCHER_TO_LEGACY[dsp.path]
  if not convert then
    return nil, "no verified legacy mapping for dispatcher path '" .. tostring(dsp.path) .. "'"
  end
  local types = {
    mode = "string",
    action = "string",
    internal = "number",
    client = "number",
    x = "number",
    y = "number",
    relative = "boolean",
    workspace = "string",
    follow = "boolean",
    out_of_group = "boolean",
    direction = "string",
    mods = "string",
    key = "string",
    window = "string",
    [1] = "string",
  }
  for key, value in pairs(dsp.args) do
    if types[key] and type(value) ~= types[key] then
      return nil, "invalid type for dispatcher field '" .. tostring(key) .. "'"
    end
    if type(value) == "number" and (value ~= value or math.abs(value) == math.huge) then
      return nil, "dispatcher numbers must be finite"
    end
  end
  if dsp.args.direction and not ({ l = true, r = true, u = true, d = true })[dsp.args.direction] then
    return nil, "unsupported direction"
  end
  local name, arg = convert(dsp.args)
  if not name then
    return nil, arg
  end
  return { dispatcher = name, arg = arg }
end

-- ---------------------------------------------------------------------------
-- Typed option normalization. The registry maps the exact option-name set of
-- the live capture to what hyprctl getoption reports (options.json is the
-- oracle). An option absent from the registry is unknown to this gate and
-- fails the comparison, which keeps the set exact in both directions.
-- ---------------------------------------------------------------------------

local function normalize_bool_as_int(v)
  if type(v) ~= "boolean" then
    return nil, "expected boolean"
  end
  return v and 1 or 0
end

local function normalize_identity(v)
  return v
end

local function normalize_gap_scalar(v)
  if type(v) ~= "number" then
    return nil, "expected number"
  end
  return string.format("%d %d %d %d", v, v, v, v)
end

-- The Lua CSS-gap type accepts an integer or a table with optional top,
-- right, bottom, left fields (LuaConfigCssGap.cpp); getoption reports the
-- four-value string.
local function normalize_gap_table(v)
  if type(v) ~= "table" then
    return nil, "expected a table with top/right/bottom/left"
  end
  return string.format("%s %s %s %s", tostring(v.top), tostring(v.right), tostring(v.bottom), tostring(v.left))
end

-- The Lua gradient type accepts a color string or a table { colors = {...},
-- angle = ... } (LuaConfigGradient.cpp); getoption reports space-separated
-- ffRRGGBB tokens plus the angle in degrees.
local function normalize_gradient(v)
  if type(v) ~= "table" then
    return nil, "expected a gradient table with colors and angle"
  end
  local out = {}
  for _, color in ipairs(v.colors or {}) do
    local hex = type(color) == "string" and color:match "^rgb%((%x%x%x%x%x%x)%)$"
    if hex then
      table.insert(out, "ff" .. hex)
    else
      table.insert(out, tostring(color))
    end
  end
  table.insert(out, tostring(v.angle or 0) .. "deg")
  return table.concat(out, " ")
end

-- Single color string form: generated conf "rgb(585b70)"; getoption appends
-- the default 0deg angle: "ff585b70 0deg".
local function normalize_color_string(v)
  if type(v) ~= "string" then
    return nil, "expected string"
  end
  local hex = v:match "^rgb%((%x%x%x%x%x%x)%)$"
  if not hex then
    return nil, "expected rgb(RRGGBB)"
  end
  return "ff" .. hex .. " 0deg"
end

local function normalize_vec2(v)
  -- generated conf: "16 9"; getoption: vec2 [16, 9]
  if type(v) ~= "string" then
    return nil, "expected string"
  end
  local x, y = v:match "^(%d+)%s+(%d+)$"
  if not x then
    return nil, "expected two numbers"
  end
  return { tonumber(x), tonumber(y) }
end

-- The registry is keyed by the dotted internal path (what hl.config walk
-- builds and what m_configValues holds); the baseline capture uses the colon
-- query syntax, mapped exactly like CConfigManager::luaConfigValueName
-- (':' to '.', '-' to '_').
records.OPTION_NORMALIZERS = {
  ["cursor.enable_hyprcursor"] = normalize_bool_as_int,
  ["misc.vrr"] = normalize_identity,
  ["misc.animate_manual_resizes"] = normalize_bool_as_int,
  ["misc.animate_mouse_windowdragging"] = normalize_bool_as_int,
  ["general.layout"] = normalize_identity,
  ["general.border_size"] = normalize_identity,
  ["general.resize_on_border"] = normalize_bool_as_int,
  ["general.gaps_in"] = normalize_gap_scalar,
  ["general.gaps_out"] = normalize_gap_table,
  ["general.col.active_border"] = normalize_gradient,
  ["general.col.inactive_border"] = normalize_color_string,
  ["layout.single_window_aspect_ratio"] = normalize_vec2,
  ["dwindle.preserve_split"] = normalize_bool_as_int,
  ["dwindle.force_split"] = normalize_identity,
  ["decoration.rounding"] = normalize_identity,
  ["decoration.blur.enabled"] = normalize_bool_as_int,
  ["master.allow_small_split"] = normalize_bool_as_int,
  ["master.mfact"] = normalize_identity,
  ["master.new_on_top"] = normalize_bool_as_int,
  ["binds.drag_threshold"] = normalize_identity,
  ["binds.allow_workspace_cycles"] = normalize_bool_as_int,
  ["xwayland.force_zero_scaling"] = normalize_bool_as_int,
  ["ecosystem.no_update_news"] = normalize_bool_as_int,
}

-- True when the dotted Lua path names an option this gate knows. Mirrors
-- hlConfig's walk in LuaBindingsConfigRules.cpp: a registered option key
-- parses its value directly (tables included); only unregistered keys recurse
-- into nested tables.
function records.known_option(dotted_path)
  return records.OPTION_NORMALIZERS[dotted_path] ~= nil
end

-- luaConfigValueName (ConfigManager.cpp): colon query form to dotted key.
function records.to_dotted(colon_name)
  return (colon_name:gsub(":", "."):gsub("%-", "_"))
end

-- Compare a Lua-side option list ({key=, value=}, ordered, dotted internal
-- paths) against the baseline getoption capture (colon query syntax). The
-- option-name set must be exact in both directions, and every value must
-- normalize to the captured shape.
function records.diff_options(lua_options, baseline_options)
  local failures = {}

  local normalized = {}
  for _, opt in ipairs(lua_options) do
    local norm = records.OPTION_NORMALIZERS[opt.key]
    if not norm then
      table.insert(failures, "unknown option (not in the registry): " .. opt.key)
    else
      local value, err = norm(opt.value)
      if value == nil then
        table.insert(failures, "option " .. opt.key .. " failed normalization: " .. tostring(err))
      else
        if normalized[opt.key] ~= nil then
          table.insert(failures, "option set twice: " .. opt.key)
        end
        normalized[opt.key] = value
      end
    end
  end

  local baseline = {}
  for _, opt in ipairs(baseline_options) do
    local value
    for _, kind in ipairs { "int", "str", "float", "vec2", "custom" } do
      if opt[kind] ~= nil then
        value = opt[kind]
      end
    end
    baseline[records.to_dotted(opt.option)] = value
  end

  for name, value in pairs(baseline) do
    if normalized[name] == nil then
      table.insert(failures, "option missing on the Lua side: " .. name)
    elseif not records.option_value_eq(normalized[name], value) then
      table.insert(
        failures,
        string.format(
          "option %s: Lua %s != baseline %s",
          name,
          records.render_option(normalized[name]),
          records.render_option(value)
        )
      )
    end
  end
  for name in pairs(normalized) do
    if baseline[name] == nil then
      table.insert(failures, "option not set in the baseline: " .. name)
    end
  end

  return failures
end

function records.option_value_eq(a, b)
  if type(a) == "table" and type(b) == "table" then
    if #a ~= #b then
      return false
    end
    for i = 1, #a do
      if a[i] ~= b[i] then
        return false
      end
    end
    return true
  end
  if type(a) == "number" and type(b) == "number" then
    return math.abs(a - b) < 1e-9
  end
  return a == b
end

function records.render_option(v)
  if type(v) == "table" then
    return "[" .. table.concat(v, ", ") .. "]"
  end
  return tostring(v)
end

-- ---------------------------------------------------------------------------
-- Disk evidence. Window rules, env entries, monitor specs, and startup
-- commands have no live dump in 0.55.4, so their parity target is the
-- captured hyprlang config: what Home Manager generated, not what the session
-- loaded. The live cross-checks (empty configerrors, agreeing getoption
-- values) support but do not prove it; the user session gate closes the gap.
-- ---------------------------------------------------------------------------

-- env records ({name=, value=}, ordered) vs the env= lines of the captured
-- config. Byte-level: env=NAME,VALUE with everything after the first comma
-- being the value verbatim.
function records.diff_env(lua_env, conf_env_lines)
  local failures = {}
  local n = math.max(#lua_env, #conf_env_lines)
  for i = 1, n do
    local lua_entry = lua_env[i]
    local conf_line = conf_env_lines[i]
    if lua_entry == nil then
      table.insert(failures, "env: missing entry at position " .. i .. " (conf has " .. conf_line .. ")")
    elseif conf_line == nil then
      table.insert(
        failures,
        "env: extra entry at position " .. i .. " (lua has " .. lua_entry.name .. "," .. lua_entry.value .. ")"
      )
    else
      local name, value = conf_line:match "^([^,]*),(.*)$"
      if name ~= lua_entry.name or value ~= lua_entry.value then
        table.insert(
          failures,
          string.format(
            "env: entry %d differs: lua %s,%s vs conf %s,%s",
            i,
            lua_entry.name,
            lua_entry.value,
            name,
            value
          )
        )
      end
    end
  end
  return failures
end

-- Disk-labeled records (structured Lua side) vs the verbatim lines captured
-- from the generated config. Each Lua record must carry a `disk` field with
-- the exact generated string it stands for; the sequence must match the
-- captured lines one for one, in order. The structured-to-string equivalence
-- itself is asserted at the live session gate, not here.
function records.diff_disk_labeled(lua_records, conf_lines, label)
  local failures = {}
  local n = math.max(#lua_records, #conf_lines)
  for i = 1, n do
    local rec, line = lua_records[i], conf_lines[i]
    if rec == nil then
      table.insert(failures, label .. ": missing record at position " .. i)
    elseif line == nil then
      table.insert(failures, label .. ": extra record at position " .. i)
    elseif rec.disk ~= line then
      table.insert(
        failures,
        string.format("%s: record %d disk label differs: %q != %q", label, i, tostring(rec.disk), tostring(line))
      )
    end
  end
  return failures
end

-- Extract the value lines of one prefix (e.g. "env" or "windowrule") from a
-- captured hyprlang config, in file order.
function records.conf_lines(conf_text, prefix)
  local out = {}
  prefix = prefix:gsub("(%W)", "%%%1")
  for line in conf_text:gmatch "[^\n]+" do
    local value = line:match("^" .. prefix .. "%s*=%s*(.+)$")
    if value then
      table.insert(out, value)
    end
  end
  return out
end

-- Workspace rules compare structurally against the live workspacerules.json
-- capture. The Lua rule's required 'workspace' string is compared with the
-- capture's workspaceString, and the persistent flag with the capture flag.
function records.diff_workspace_rules(lua_rules, baseline_rules)
  local failures = {}
  local n = math.max(#lua_rules, #baseline_rules)
  for i = 1, n do
    local lua_rule, base = lua_rules[i], baseline_rules[i]
    if lua_rule == nil then
      table.insert(failures, "workspace rules: missing record at position " .. i)
    elseif base == nil then
      table.insert(failures, "workspace rules: extra record at position " .. i)
    else
      for key in pairs(lua_rule) do
        if key ~= "workspace" and key ~= "persistent" and key ~= "enabled" then
          table.insert(failures, "workspace rules: unsupported Lua field " .. tostring(key))
        end
      end
      for key in pairs(base) do
        if key ~= "workspaceString" and key ~= "persistent" then
          table.insert(failures, "workspace rules: unsupported baseline field " .. tostring(key))
        end
      end
      if lua_rule.enabled ~= nil and lua_rule.enabled ~= true then
        table.insert(failures, "workspace rules: enabled must be true or omitted")
      end
      local lua_string = tostring(lua_rule.workspace)
      if lua_string ~= base.workspaceString then
        table.insert(
          failures,
          string.format("workspace rules: entry %d: %q != %q", i, lua_string, base.workspaceString)
        )
      end
      if type(lua_rule.persistent) ~= "boolean" or lua_rule.persistent ~= base.persistent then
        table.insert(failures, "workspace rules: entry " .. i .. ": persistent flag differs")
      end
    end
  end
  return failures
end

-- Monitor spec grammar, verified against the pinned source: legacy lines are
-- "NAME, MODE, POSITION, SCALE, [key, value]*" (ConfigManager.cpp
-- handleMonitor) with short forms "NAME, disable|disabled",
-- "NAME, transform, N", "NAME, addreserved, T, R, B, L". The Lua side is the
-- typed hl.monitor table (MONITOR_FIELDS in LuaBindingsConfigRules.cpp).
-- parse_monitor_spec returns the spec fields the line explicitly states, or
-- nil plus an error for unknown syntax.
function records.parse_monitor_spec(line)
  local tokens = {}
  for token in line:gmatch "[^,]+" do
    table.insert(tokens, token:match "^%s*(.-)%s*$")
  end
  local spec = { output = tokens[1] }
  if spec.output == nil then
    return nil, "empty monitor line"
  end

  local second = tokens[2]
  if second == "disable" or second == "disabled" then
    spec.disabled = true
    return spec
  elseif second == "transform" then
    if tokens[3] == nil then
      return nil, "transform short form needs a value"
    end
    spec.transform = tokens[3]
    return spec
  elseif second == "addreserved" then
    if #tokens ~= 6 then
      return nil, "addreserved short form needs top right bottom left"
    end
    spec.reserved = tokens[3] .. " " .. tokens[4] .. " " .. tokens[5] .. " " .. tokens[6]
    return spec
  end

  spec.mode = second
  spec.position = tokens[3]
  spec.scale = tokens[4]

  local known_keys = {
    mirror = true,
    bitdepth = true,
    cm = true,
    sdrsaturation = true,
    sdrbrightness = true,
    transform = true,
    vrr = true,
    icc = true,
  }
  local i = 5
  while tokens[i] ~= nil do
    local key = tokens[i]
    if not known_keys[key] then
      return nil, 'invalid monitor syntax at "' .. key .. '"'
    end
    if tokens[i + 1] == nil then
      return nil, "monitor key '" .. key .. "' has no value"
    end
    spec[key] = tokens[i + 1]
    i = i + 2
  end
  return spec
end

-- Defaults from MONITOR_FIELDS factories (LuaBindingsConfigRules.cpp); the
-- Lua table defaults are the values absence produces.
local MONITOR_DEFAULTS = {
  mode = "preferred",
  position = "auto",
  scale = "auto",
  disabled = false,
  bitdepth = "8",
  cm = "srgb",
  transform = "0",
  mirror = "",
  vrr = "0",
  sdrbrightness = "1",
  sdrsaturation = "1",
}

local MONITOR_FIELDS = {
  "mode",
  "position",
  "scale",
  "disabled",
  "bitdepth",
  "cm",
  "transform",
  "mirror",
  "vrr",
  "sdrbrightness",
  "sdrsaturation",
}

local function monitor_value(v)
  return tostring(v)
end

-- Full spec parity: every monitor field explicitly present on either side
-- must agree on the other side or match the factory default. A record with
-- disabled=false against a "HDMI-A-1, disable" line fails, as does a changed
-- mode, scale, or bitdepth.
function records.diff_monitors(lua_monitors, conf_lines)
  local failures = {}
  local n = math.max(#lua_monitors, #conf_lines)
  for i = 1, n do
    local rule, line = lua_monitors[i], conf_lines[i]
    if rule == nil then
      table.insert(failures, "monitors: missing record at position " .. i)
    elseif line == nil then
      table.insert(failures, "monitors: extra record at position " .. i)
    else
      local spec, err = records.parse_monitor_spec(line)
      if not spec then
        table.insert(failures, "monitors: entry " .. i .. ": " .. err)
      else
        if rule.output ~= spec.output then
          table.insert(
            failures,
            string.format("monitors: entry %d: output %q != %q", i, tostring(rule.output), tostring(spec.output))
          )
        end
        for _, field in ipairs(MONITOR_FIELDS) do
          local line_value = spec[field]
          local lua_value = rule[field]
          if line_value ~= nil and lua_value ~= nil then
            if monitor_value(line_value) ~= monitor_value(lua_value) then
              table.insert(
                failures,
                string.format(
                  "monitors: entry %d (%s): %s != %s",
                  i,
                  field,
                  monitor_value(lua_value),
                  monitor_value(line_value)
                )
              )
            end
          elseif line_value ~= nil then
            if monitor_value(line_value) ~= monitor_value(MONITOR_DEFAULTS[field]) then
              table.insert(
                failures,
                string.format(
                  "monitors: entry %d (%s): line states %s, record omits it (default %s)",
                  i,
                  field,
                  monitor_value(line_value),
                  MONITOR_DEFAULTS[field]
                )
              )
            end
          elseif lua_value ~= nil and monitor_value(lua_value) ~= monitor_value(MONITOR_DEFAULTS[field]) then
            table.insert(
              failures,
              string.format(
                "monitors: entry %d (%s): record states %s, line omits it (default %s)",
                i,
                field,
                monitor_value(lua_value),
                MONITOR_DEFAULTS[field]
              )
            )
          end
        end
        for key in pairs(rule) do
          if key ~= "output" and MONITOR_DEFAULTS[key] == nil then
            table.insert(failures, "monitors: entry " .. i .. ": unsupported field '" .. tostring(key) .. "'")
          end
        end
      end
    end
  end
  return failures
end

-- Window rule effect names from WINDOW_RULE_EFFECT_DESCS
-- (LuaBindingsInternal.hpp). The dynamic effect registry is not modeled.
records.WINDOW_RULE_EFFECTS = {
  float = true,
  tile = true,
  fullscreen = true,
  maximize = true,
  center = true,
  pseudo = true,
  no_initial_focus = true,
  pin = true,
  fullscreen_state = true,
  move = true,
  size = true,
  monitor = true,
  workspace = true,
  group = true,
  suppress_event = true,
  content = true,
  no_close_for = true,
  scrolling_width = true,
  rounding = true,
  border_size = true,
  rounding_power = true,
  scroll_mouse = true,
  scroll_touchpad = true,
  animation = true,
  idle_inhibit = true,
  opacity = true,
  tag = true,
  max_size = true,
  min_size = true,
  border_color = true,
  persistent_size = true,
  allows_input = true,
  dim_around = true,
  decorate = true,
  focus_on_activate = true,
  keep_aspect_ratio = true,
  nearest_neighbor = true,
  no_anim = true,
  no_blur = true,
  no_dim = true,
  no_focus = true,
  no_follow_mouse = true,
  no_max_size = true,
  no_shadow = true,
  no_shortcuts_inhibit = true,
  opaque = true,
  force_rgbx = true,
  sync_fullscreen = true,
  immediate = true,
  xray = true,
  render_unfocused = true,
  no_screen_share = true,
  no_vrr = true,
  stay_focused = true,
  confine_pointer = true,
}

-- Window rule records vs the captured windowrule= lines, two-way. The
-- captured syntax is "<effect> <value>, match:<prop> <value>, ...". The
-- comparison requires: the rule enabled, the record's effect set exactly the
-- line's effect with an equal value ("on" maps to boolean true), and the
-- record's match table exactly the line's match tokens in both directions.
-- The rendered-string equivalence is asserted at the live session gate.
function records.diff_window_rules(lua_rules, conf_lines)
  local failures = {}
  local n = math.max(#lua_rules, #conf_lines)
  for i = 1, n do
    local rule, line = lua_rules[i], conf_lines[i]
    if rule == nil then
      table.insert(failures, "window rules: missing record at position " .. i)
    elseif line == nil then
      table.insert(failures, "window rules: extra record at position " .. i)
    else
      if rule.enabled == false then
        table.insert(failures, "window rules: entry " .. i .. ": rule disabled on the Lua side but generated on disk")
      end

      local tokens = {}
      for token in line:gmatch "[^,]+" do
        table.insert(tokens, token:match "^%s*(.-)%s*$")
      end
      local effect, value = tokens[1]:match "^(%S+)%s*(.*)$"

      local record_effects = {}
      for key, val in pairs(rule) do
        if records.WINDOW_RULE_EFFECTS[key] then
          record_effects[key] = val
        end
      end

      if effect == nil or record_effects[effect] == nil then
        table.insert(failures, "window rules: entry " .. i .. ": record has no effect '" .. tostring(effect) .. "'")
      elseif value == "on" then
        if record_effects[effect] ~= true then
          table.insert(failures, "window rules: entry " .. i .. ": effect '" .. effect .. "' is not on")
        end
      elseif tostring(record_effects[effect]) ~= value then
        table.insert(
          failures,
          string.format(
            "window rules: entry %d: effect %s: %s != %s",
            i,
            effect,
            tostring(record_effects[effect]),
            value
          )
        )
      end

      local record_match = rule.match or {}
      for key in pairs(record_effects) do
        if key ~= effect then
          table.insert(failures, "window rules: entry " .. i .. ": record has extra effect '" .. key .. "'")
        end
      end

      local seen_match = {}
      for t = 2, #tokens do
        local prop, val = tokens[t]:match "^match:(%S+)%s+(.+)$"
        if prop == nil then
          table.insert(failures, "window rules: entry " .. i .. ": unmatched token '" .. tokens[t] .. "'")
        else
          seen_match[prop] = val
          if record_match[prop] == nil then
            table.insert(failures, "window rules: entry " .. i .. ": record has no match:" .. prop)
          elseif tostring(record_match[prop]) ~= val then
            table.insert(
              failures,
              string.format("window rules: entry %d: match:%s %s != %s", i, prop, tostring(record_match[prop]), val)
            )
          end
        end
      end
      for prop in pairs(record_match) do
        if seen_match[prop] == nil then
          table.insert(failures, "window rules: entry " .. i .. ": record has extra match:" .. tostring(prop))
        end
      end
    end
  end
  return failures
end

function records.diff_startup(state, conf_text, dbus_executable)
  local failures = {}
  local seen = {}
  for _, event in ipairs(state.events) do
    if event ~= "hyprland.start" and event ~= "hyprland.shutdown" then
      table.insert(failures, "unsupported event registration: " .. event)
    end
    seen[event] = true
  end
  if #state.exec > 0 then
    table.insert(failures, "config-level commands are not exec-once commands")
  end
  for event, prefix in pairs { ["hyprland.start"] = "exec-once", ["hyprland.shutdown"] = "exec-shutdown" } do
    local expected = records.conf_lines(conf_text, prefix)
    -- Approved in issue 37: retain the pinned Home Manager Lua shutdown hook.
    if
      event == "hyprland.shutdown"
      and #expected == 1
      and expected[1] == "systemctl --user stop hyprland-session.target"
    then
      expected[1] = "systemctl --user stop hyprland-session.target && sleep 0.1"
    end
    if #expected > 0 and not seen[event] then
      table.insert(failures, "missing event: " .. event)
    end
    if dbus_executable then
      local redacted = "/nix/store/<hash>/bin/dbus-update-activation-environment"
      for i, command in ipairs(expected) do
        if command:sub(1, #redacted + 1) == redacted .. " " then
          expected[i] = dbus_executable .. command:sub(#redacted + 1)
        end
      end
    end
    local actual = state.lifecycle and state.lifecycle[event]
    if not actual then
      table.insert(failures, "lifecycle callbacks were not captured: " .. event)
    else
      for _, failure in
        ipairs(records.diff_ordered(expected, actual, function(a, b)
          return a == b
        end, event))
      do
        table.insert(failures, failure)
      end
    end
  end
  return failures
end

return records
