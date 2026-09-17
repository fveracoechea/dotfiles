-- Production semantic parity gate. Run under Lua 5.5:
--
--   lua parity-test.lua <repo-root> <staged-hyprland.lua> <dbus-executable>
--
-- Execute the production config/hypr entry under the recorder stub, and
-- compare the records against the live baseline capture: every bind (ordered,
-- full records, both-way coverage), the exact typed option set, workspace
-- rules, and the disk-evidence surfaces (env, monitor specs, window rules).
--
-- The caller (the Nix check) must export XDG_CONFIG_HOME to a directory
-- containing dotfiles/hyprland.json with the bridge data derived from the
-- capture: monitor specs, raw-hex theme colors, and the fuzzel cache path.
--
-- This gate is red until the port ticket adds config/hypr; that is the point.
-- It must not be weakened to pass while the hyprlang configuration still owns
-- the compositor.

local function script_dir()
  local src = debug.getinfo(1, "S").source:sub(2)
  return src:match "^(.*)/" or "."
end

local here = script_dir()
local root = (arg and arg[1]) or here .. "/../.."
local production = root .. "/config/hypr"

local function die(message)
  io.stderr:write("parity-test: " .. message .. "\n")
  os.exit(1)
end

local entry_path = production .. "/entry.lua"
local entry = io.open(entry_path, "r")
if not entry then
  die(
    "config/hypr/entry.lua does not exist yet; the verification harness is "
      .. "in place and the port ticket (configType flip to lua plus the "
      .. "config/hypr modules) must land before this gate can run"
  )
end
entry:close()

local staged_entry, dbus_executable = arg[2], arg[3]
if not staged_entry or not dbus_executable then
  die "staged Home Manager hyprland.lua and dbus executable arguments are required"
end
local staged_directory = staged_entry:match "^(.*)/[^/]+$"
if not staged_directory then
  die "staged entry must include its directory"
end

package.path = here .. "/?.lua;" .. package.path

local records = require "records"
local capture = require "capture"
local json = require "lib.json"

local baseline = root .. "/docs/research/hyprland-live-baseline"

local function read_json(path)
  local f = assert(io.open(path, "r"))
  local data = assert(json.decode(f:read "*a"))
  f:close()
  return data
end

local function read(path)
  local f = assert(io.open(path, "r"))
  local text = f:read "*a"
  f:close()
  return text
end

-- Prepare a data bridge from the captured facts: monitor specs from the
-- generated config, theme colors from the palette the config applies, the
-- fuzzel cache path from the captured fuzzel exec line. The caller (the Nix
-- check) must export XDG_CONFIG_HOME to a directory before this script runs;
-- the production bridge resolves the file from that variable at load time.
local xdg = os.getenv "XDG_CONFIG_HOME"
if not xdg or xdg == "" then
  die(
    "XDG_CONFIG_HOME is not set; the check must export it to a directory "
      .. "containing dotfiles/hyprland.json before running this gate"
  )
end

local state = capture.run(read(staged_entry), staged_directory, "@" .. staged_entry)
assert(#state.errors == 0, table.concat(state.errors, "\n"))

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

local function canonicalize(binds)
  local out = {}
  for _, bind in ipairs(binds) do
    local legacy, err = records.legacy_dispatcher(bind.dispatcher)
    if not legacy then
      die("production bind dispatcher mapping failed: " .. tostring(err))
    end
    out[#out + 1] = records.normalize_mouse_flag {
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
  end
  return out
end

print "== binds: full ordered records, both-way coverage =="
do
  local baseline_binds = read_json(baseline .. "/hyprctl/binds.json")
  local expected = {}
  for _, entry_ in ipairs(baseline_binds) do
    expected[#expected + 1] = records.canonical_baseline_bind(entry_)
  end
  local produced = canonicalize(state.binds)
  report(#produced == #expected, "record counts match (" .. #produced .. " vs " .. #expected .. ")")
  local d = records.diff_ordered(expected, produced, records.bind_eq, "binds")
  local detail = {}
  for i, line in ipairs(d) do
    if i > 8 then
      table.insert(detail, "...")
      break
    end
    table.insert(detail, line)
  end
  report(#d == 0, "ordered positional match of every bind record", detail)
end

print "== typed options: exact set =="
do
  local baseline_options = read_json(baseline .. "/hyprctl/options.json")
  local d = records.diff_options(state.options, baseline_options)
  local detail = {}
  for i, line in ipairs(d) do
    if i > 8 then
      table.insert(detail, "...")
      break
    end
    table.insert(detail, line)
  end
  report(#d == 0, "option set and normalized values match the capture", detail)
end

print "== workspace rules =="
do
  local baseline_ws = read_json(baseline .. "/hyprctl/workspacerules.json")
  local d = records.diff_workspace_rules(state.workspace_rules, baseline_ws)
  report(#d == 0, "workspace rules match the capture", d)
end

print "== disk evidence: env, monitors, window rules =="
do
  local conf_text = read(baseline .. "/generated/hyprland.conf")
  local conf_monitors = records.conf_lines(conf_text, "monitor")

  local d = records.diff_env(state.env, records.conf_lines(conf_text, "env"))
  report(#d == 0, "env entries match the captured config byte for byte", d)

  d = records.diff_monitors(state.monitors, conf_monitors)
  report(#d == 0, "monitor records pair with the captured monitor= lines", d)

  d = records.diff_window_rules(state.window_rules, records.conf_lines(conf_text, "windowrule"))
  report(#d == 0, "window rule records match the captured windowrule= lines", d)

  d = records.diff_startup(state, conf_text, dbus_executable)
  report(#d == 0, "startup matches the capture; shutdown matches the approved Home Manager exception", d)
end

print(
  failures == 0 and "== production parity: all " .. checks .. " checks pass =="
    or "== production parity: " .. failures .. " failure(s) of " .. checks .. " =="
)
os.exit(failures == 0 and 0 or 1)
