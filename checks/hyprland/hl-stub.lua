-- A recording stub of the Hyprland 0.55.4 Lua configuration API.
--
-- Every accepted call shape is verified against the pinned source; see
-- api.md for the file and line references. The stub is deliberately strict:
--
--   - hl.bind mirrors parseKeyString and hlBind in
--     src/config/lua/bindings/LuaBindingsToplevel.cpp: modifiers must come
--     first, mods resolve through the IKeyboard.hpp bit values, code:N and
--     mouse:* / switch:* / mouse_down-style keys are recognized, catchall is
--     only legal inside a submap, and the dispatcher must be a dispatcher
--     object with a verified legacy mapping. Function dispatchers are unsupported.
--   - hl.dsp only exposes the dispatcher constructors with a verified legacy
--     mapping in records.lua. Any other path raises an error, so a config
--     cannot silently call an API shape nobody verified.
--   - Options, env, monitors, window rules, workspace rules, events and
--     config-level exec calls are recorded in call order for parity.
--
-- The stub runs on plain Lua 5.5, the interpreter version Hyprland 0.55.4
-- embeds (CMakeLists.txt asks pkg-config for lua55/lua5.5).

local records = require "records"

local stub = {}

local function snapshot(value, active)
  if type(value) ~= "table" then
    return value
  end
  active = active or {}
  if active[value] or getmetatable(value) then
    error("recorder requires plain acyclic tables", 3)
  end
  active[value] = true
  local out = {}
  for k, v in pairs(value) do
    out[k] = snapshot(v, active)
  end
  active[value] = nil
  return out
end

local MOD_BITS = {
  SHIFT = 1,
  CAPS = 2,
  CTRL = 4,
  CONTROL = 4,
  ALT = 8,
  MOD1 = 8,
  MOD2 = 16,
  MOD3 = 32,
  SUPER = 64,
  WIN = 64,
  LOGO = 64,
  MOD4 = 64,
  META = 64,
  MOD5 = 128,
}

-- knownEvents() in src/config/lua/LuaEventHandler.cpp
local KNOWN_EVENTS = {
  ["window.open"] = true,
  ["window.open_early"] = true,
  ["window.close"] = true,
  ["window.destroy"] = true,
  ["window.kill"] = true,
  ["window.active"] = true,
  ["window.urgent"] = true,
  ["window.title"] = true,
  ["window.class"] = true,
  ["window.pin"] = true,
  ["window.fullscreen"] = true,
  ["window.update_rules"] = true,
  ["window.move_to_workspace"] = true,
  ["layer.opened"] = true,
  ["layer.closed"] = true,
  ["monitor.added"] = true,
  ["monitor.removed"] = true,
  ["monitor.focused"] = true,
  ["monitor.layout_changed"] = true,
  ["workspace.active"] = true,
  ["workspace.created"] = true,
  ["workspace.removed"] = true,
  ["workspace.move_to_monitor"] = true,
  ["config.reloaded"] = true,
  ["keybinds.submap"] = true,
  ["screenshare.state"] = true,
  ["hyprland.start"] = true,
  ["hyprland.shutdown"] = true,
}

local KNOWN_DISPATCHERS = {
  "window.close",
  "window.float",
  "window.fullscreen",
  "window.fullscreen_state",
  "window.pseudo",
  "window.resize",
  "window.drag",
  "window.move",
  "group.toggle",
  "focus",
  "exec_cmd",
  "layout",
  "send_shortcut",
}

-- parseKeyString in LuaBindingsToplevel.cpp: '+'-separated, whitespace
-- tolerated, modifiers first, special syms and code:N recognized.
local function parse_key_string(keys)
  if keys == "catchall" then
    return 0, "", 0, true
  end

  local modmask = 0
  local key = nil
  local keycode = 0
  local mods_ended = false

  for chunk in (keys .. "+"):gmatch "(.-)%+" do
    local part = chunk:match "^%s*(.-)%s*$"
    if part == "" or part:find "%s" then
      error("hl.bind: expected plus-separated keys", 3)
    end
    local bit = MOD_BITS[part]
    if bit then
      if mods_ended then
        error("hl.bind: Modifiers must come first in the list: '" .. keys .. "'", 3)
      end
      modmask = modmask | bit
    else
      if key then
        error("hl.bind: multi-key chords are unsupported", 3)
      end
      mods_ended = true
      if part:match "^code:%d+$" then
        keycode = tonumber(part:sub(6))
        key = part
      elseif
        part:match "^mouse:%d+$"
        or part:match "^switch:.+$"
        or part == "mouse_down"
        or part == "mouse_up"
        or part == "mouse_left"
        or part == "mouse_right"
      then
        key = part
      else
        key = part
      end
    end
  end

  if not key then
    error("hl.bind: no key in key string: '" .. keys .. "'", 3)
  end
  return modmask, key, keycode, false
end

local function make_dispatcher(path, args)
  local descriptor = { path = path, args = snapshot(args) }
  local mapped, err = records.legacy_dispatcher(descriptor)
  if not mapped then
    error("hl.dsp." .. path .. ": " .. err, 3)
  end
  -- Callable table: the stub needs to tag dispatcher objects with their
  -- identity, and plain Lua functions cannot carry fields.
  local obj = setmetatable({
    __hl_dispatcher = descriptor,
  }, {
    __call = function()
      error("dispatcher objects cannot be called directly; use hl.dispatch(dispatcher)", 2)
    end,
    __tostring = function()
      return "HL.Dispatcher(" .. path .. ")"
    end,
  })
  return obj
end

local function table_ctor(path)
  return function(args, ...)
    if select("#", ...) > 0 then
      error("hl.dsp." .. path .. ": extra arguments are unsupported", 2)
    end
    -- Real constructors read optional fields from arg 1; calling with no
    -- arguments is legal (e.g. hl.dsp.window.close()).
    if args ~= nil and type(args) ~= "table" then
      error("hl.dsp." .. path .. ": expected a table of arguments", 2)
    end
    return make_dispatcher(path, args or {})
  end
end

local function str_ctor(path)
  return function(str, ...)
    if select("#", ...) > 0 then
      error("hl.dsp." .. path .. ": extra arguments are unsupported", 2)
    end
    if type(str) ~= "string" or str == "" then
      error("hl.dsp." .. path .. ": expected a non-empty string", 2)
    end
    return make_dispatcher(path, { str })
  end
end

function stub.new()
  local state = {
    binds = {},
    options = {},
    env = {},
    monitors = {},
    window_rules = {},
    workspace_rules = {},
    events = {},
    callbacks = {},
    exec = {},
    current_submap = "",
  }

  local hl = {}
  local rule_names = {}

  -- LuaBindingsToplevel.cpp hlBind
  function hl.bind(keys, dsp, opts)
    if type(keys) ~= "string" then
      error("hl.bind: bad argument 1: expected a key string", 2)
    end
    local is_dispatcher = (
      type(dsp) == "table"
      and type(getmetatable(dsp)) == "table"
      and getmetatable(dsp).__call ~= nil
      and dsp.__hl_dispatcher ~= nil
    )
    if not is_dispatcher then
      error("hl.bind: only verified dispatcher objects are supported, not Lua callbacks", 2)
    end

    local modmask, key, keycode, catch_all = parse_key_string(keys)
    if catch_all and state.current_submap == "" then
      error("hl.bind: catchall keybinds are only allowed in submaps.", 2)
    end

    local record = {
      modmask = modmask,
      key = key,
      keycode = keycode,
      submap = state.current_submap,
      catch_all = catch_all,
      description = "",
      has_description = false,
      flags = {
        locked = false,
        mouse = false,
        release = false,
        ["repeat"] = false,
        longPress = false,
        non_consuming = false,
        auto_consuming = false,
      },
      dispatcher = snapshot(dsp.__hl_dispatcher),
    }
    if type(opts) == "table" then
      local allowed = {
        locked = "boolean",
        release = "boolean",
        repeating = "boolean",
        non_consuming = "boolean",
        auto_consuming = "boolean",
        long_press = "boolean",
        description = "string",
        desc = "string",
      }
      for name, value in pairs(opts) do
        if type(value) ~= allowed[name] then
          error("hl.bind: unsupported option or type: " .. tostring(name), 2)
        end
      end
      record.flags.locked = opts.locked == true
      record.flags.release = opts.release == true
      record.flags["repeat"] = opts.repeating == true
      record.flags.non_consuming = opts.non_consuming == true
      record.flags.auto_consuming = opts.auto_consuming == true
      record.flags.longPress = opts.long_press == true
      if (opts.long_press == true or opts.release == true) and opts.repeating == true then
        error("hl.bind: long_press / release is incompatible with repeat", 2)
      end
      if opts.description or opts.desc then
        record.description = opts.description or opts.desc
        record.has_description = true
      end
    elseif opts ~= nil then
      error("hl.bind: options must be a table", 2)
    end
    table.insert(state.binds, record)
    return snapshot(record)
  end

  -- LuaBindingsToplevel.cpp hlDefineSubmap
  function hl.define_submap(name, reset_or_fn, maybe_fn)
    if maybe_fn ~= nil then
      error("hl.define_submap: reset extensions are unsupported", 2)
    end
    if type(name) ~= "string" then
      error("hl.define_submap: bad argument 1: expected a name", 2)
    end
    local fn = maybe_fn or reset_or_fn
    if type(fn) ~= "function" then
      error("hl.define_submap: expected a function", 2)
    end
    local prev = state.current_submap
    state.current_submap = name
    fn()
    state.current_submap = prev
  end

  -- LuaBindingsConfigRules.cpp hlConfig: nested tables flatten to dotted
  -- paths ("general.gaps_in"); the colon form is the hyprctl query syntax,
  -- mapped by luaConfigValueName (ConfigManager.cpp). A registered option key
  -- records its value directly, tables included (that is how the typed gap
  -- and gradient values arrive); only unregistered keys recurse deeper.
  function hl.config(options)
    if type(options) ~= "table" then
      error("hl.config: argument must be a table", 2)
    end
    local function walk(prefix, table_)
      for key, value in pairs(table_) do
        if type(key) ~= "string" then
          goto continue
        end
        local path = prefix == "" and key or (prefix .. "." .. key)
        if type(value) == "table" and not records.known_option(path) then
          local known_prefix = false
          for name in pairs(records.OPTION_NORMALIZERS) do
            if name:sub(1, #path + 1) == path .. "." then
              known_prefix = true
              break
            end
          end
          if not known_prefix then
            error("hl.config: unsupported option " .. path, 2)
          end
          walk(path, value)
        else
          table.insert(state.options, { key = path, value = snapshot(value) })
        end
        ::continue::
      end
    end
    walk("", options)
  end

  -- LuaBindingsConfigRules.cpp hlEnv
  function hl.env(name, value)
    if type(name) ~= "string" or name == "" then
      error("hl.env: first argument (name) must be a non-empty string", 2)
    end
    if type(value) ~= "string" then
      error("hl.env: second argument (value) must be a string", 2)
    end
    table.insert(state.env, { name = name, value = value })
  end

  -- LuaBindingsConfigRules.cpp hlMonitor: typed fields, "output" required.
  function hl.monitor(rule)
    if type(rule) ~= "table" then
      error("hl.monitor: argument must be a table", 2)
    end
    if type(rule.output) ~= "string" then
      error("hl.monitor: 'output' field is required and must be a string", 2)
    end
    local known = {
      mode = true,
      position = true,
      scale = true,
      disabled = true,
      transform = true,
      reserved = true,
      mirror = true,
      bitdepth = true,
      cm = true,
      vrr = true,
    }
    for key in pairs(rule) do
      if key ~= "output" and not known[key] then
        error("hl.monitor: unknown field '" .. tostring(key) .. "'", 2)
      end
    end
    table.insert(state.monitors, snapshot(rule))
  end

  -- LuaBindingsConfigRules.cpp hlWindowRule: structural keys plus the effect
  -- names from WINDOW_RULE_EFFECT_DESCS (LuaBindingsInternal.hpp). The
  -- dynamic effect registry is not modeled; the stub rejects unknown names.
  local WINDOW_RULE_KEYS = {
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
  function hl.window_rule(rule)
    if type(rule) ~= "table" then
      error("hl.window_rule: argument must be a table", 2)
    end
    for key in pairs(rule) do
      if key ~= "name" and key ~= "enabled" and key ~= "match" and not WINDOW_RULE_KEYS[key] then
        error("hl.window_rule: unknown field '" .. tostring(key) .. "'", 2)
      end
    end
    if rule.name ~= nil then
      if type(rule.name) ~= "string" then
        error("hl.window_rule: name must be a string", 2)
      end
      if rule.name ~= "" then
        if rule_names[rule.name] then
          error("hl.window_rule: repeated names are unsupported", 2)
        end
        rule_names[rule.name] = true
      end
    end
    table.insert(state.window_rules, snapshot(rule))
  end

  -- LuaBindingsConfigRules.cpp hlWorkspaceRule: 'workspace' is required;
  -- other fields come from WORKSPACE_RULE_FIELDS in the same file.
  local WORKSPACE_RULE_KEYS = {
    monitor = true,
    ["default"] = true,
    persistent = true,
    gaps_in = true,
    gaps_out = true,
    float_gaps = true,
    border_size = true,
    no_border = true,
    no_rounding = true,
    decorate = true,
    no_shadow = true,
    on_created_empty = true,
    default_name = true,
    layout = true,
    animation = true,
  }
  function hl.workspace_rule(rule)
    if type(rule) ~= "table" then
      error("hl.workspace_rule: argument must be a table", 2)
    end
    if type(rule.workspace) ~= "string" then
      error("hl.workspace_rule: 'workspace' field is required and must be a string", 2)
    end
    for key in pairs(rule) do
      if key ~= "workspace" and key ~= "enabled" and key ~= "layout_opts" and not WORKSPACE_RULE_KEYS[key] then
        error("hl.workspace_rule: unknown field '" .. tostring(key) .. "'", 2)
      end
    end
    table.insert(state.workspace_rules, snapshot(rule))
  end

  -- LuaBindingsToplevel.cpp hlOn
  function hl.on(event, fn)
    if type(event) ~= "string" or not KNOWN_EVENTS[event] then
      error('hl.on: unknown event "' .. tostring(event) .. '"', 2)
    end
    if type(fn) ~= "function" then
      error("hl.on: expected a function", 2)
    end
    table.insert(state.events, event)
    table.insert(state.callbacks, { event = event, fn = fn })
  end

  -- LuaBindingsToplevel.cpp hlExecCmd: config-level spawns are recorded so
  -- startup parity can compare them; the real call spawns immediately.
  function hl.exec_cmd(cmd)
    if type(cmd) ~= "string" or cmd == "" then
      error("hl.exec_cmd: expected command as first argument", 2)
    end
    table.insert(state.exec, cmd)
  end

  local dsp = {}
  dsp.window = {}
  dsp.group = {}
  dsp.window.close = table_ctor "window.close"
  dsp.window.float = table_ctor "window.float"
  dsp.window.fullscreen = table_ctor "window.fullscreen"
  dsp.window.fullscreen_state = table_ctor "window.fullscreen_state"
  dsp.window.pseudo = table_ctor "window.pseudo"
  dsp.window.resize = table_ctor "window.resize"
  dsp.window.drag = table_ctor "window.drag"
  dsp.window.move = table_ctor "window.move"
  dsp.group.toggle = table_ctor "group.toggle"
  dsp.focus = table_ctor "focus"
  dsp.exec_cmd = str_ctor "exec_cmd"
  dsp.layout = str_ctor "layout"
  dsp.send_shortcut = table_ctor "send_shortcut"

  setmetatable(dsp, {
    __index = function(_, key)
      error(
        "unknown dispatcher path 'hl.dsp."
          .. tostring(key)
          .. "' (verified paths: "
          .. table.concat(KNOWN_DISPATCHERS, ", ")
          .. ")",
        2
      )
    end,
  })

  hl.dsp = dsp
  return hl, state
end

-- Run a list of module functions under a fresh stub, in order. Each function
-- receives the stub hl table, matching how the port's modules receive it.
function stub.run(modules)
  local hl, state = stub.new()
  local previous = _G.hl
  _G.hl = hl
  local ok, err = pcall(function()
    for _, fn in ipairs(modules) do
      fn(hl)
    end
  end)
  _G.hl = previous
  if not ok then
    error(err, 0)
  end
  return state
end

return stub
