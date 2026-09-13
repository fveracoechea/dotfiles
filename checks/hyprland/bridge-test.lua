-- Bridge contract tests. Run under Lua 5.5:
--
--   lua bridge-test.lua <repo-root>
--
-- Every rejection case must fail BEFORE any caller could apply settings, and
-- the error must name the reason. No defaults are invented anywhere.

local function script_dir()
  local src = debug.getinfo(1, "S").source:sub(2)
  return src:match "^(.*)/" or "."
end

local here = script_dir()
package.path = here .. "/?.lua;" .. here .. "/lib/?.lua;" .. package.path

local bridge = require "bridge"

local failures = 0
local checks = 0

local function assert_true(condition, label)
  checks = checks + 1
  if condition then
    print("  ok   " .. label)
  else
    failures = failures + 1
    print("  FAIL " .. label)
  end
end

local function fixture(name)
  return here .. "/fixtures/bridge/" .. name
end

local function expect_reject(name, label)
  local data, err = bridge.load(fixture(name))
  assert_true(data == nil and type(err) == "string" and #err > 0, label .. " rejected (" .. tostring(err) .. ")")
end

print "== bridge acceptance =="
do
  local data = bridge.load(fixture "valid.json")
  assert_true(data ~= nil, "valid.json accepted")
  if data then
    assert_true(
      #data.monitors == 2 and data.monitors[1]:find("DP-1", 1, true) ~= nil,
      "valid.json monitors decoded in order"
    )
    assert_true(data.theme.blue == "#89b4fa", "valid.json theme.blue raw hex")
    assert_true(data.paths.fuzzelCache == "/home/fveracoechea/.cache/fuzzel", "valid.json fuzzelCache absolute")
  end
end

print "== bridge rejections (no defaults) =="
expect_reject("missing-monitors.json", "missing monitors")
expect_reject("missing-theme.json", "missing theme")
expect_reject("missing-theme-color.json", "missing one theme color")
expect_reject("missing-paths.json", "missing paths")
expect_reject("missing-fuzzel-cache.json", "missing fuzzelCache")
expect_reject("empty-monitors.json", "empty monitors array")
expect_reject("wrong-type-monitors.json", "monitors not an array")
expect_reject("malformed.json", "malformed JSON")
expect_reject("null-color.json", "null theme color")
expect_reject("null-monitors.json", "null monitors")
expect_reject("null-in-monitors.json", "null inside monitors array")
expect_reject("null-trailing-monitors.json", "trailing nulls inside monitors array")
expect_reject("null-fuzzel-cache.json", "null fuzzelCache")
expect_reject("bad-hex.json", "non-hex color format")
expect_reject("short-hex.json", "truncated hex color")
expect_reject("relative-path.json", "relative fuzzelCache path")
expect_reject("top-level-array.json", "top-level JSON array")

-- The pinned rxi/json.lua v0.1.2 decoder accepts a trailing comma; the
-- structure still decodes cleanly, so the schema decides acceptance. This is
-- evidence of decoder permissiveness, not a claim of strict JSON.
print "== decoder permissiveness (documented evidence) =="
do
  local data = bridge.load(fixture "trailing-comma.json")
  assert_true(data ~= nil, "trailing comma accepted by pinned decoder (documented)")
end
do
  -- The vendored decoder carries one local deviation from upstream: JSON null
  -- decodes to the json.null sentinel instead of nil, so an explicit null
  -- anywhere in the bridge schema is rejected instead of dropped or hidden.
  local json = require "lib.json"
  assert_true(type(json.null) == "table", "decoder keeps a json.null sentinel (documented deviation)")
end

print "== bridge path resolution =="
do
  local path = bridge.default_path()
  assert_true(
    path ~= nil and path:sub(-#"/dotfiles/hyprland.json") == "/dotfiles/hyprland.json",
    "default_path ends with dotfiles/hyprland.json"
  )
end

print(
  failures == 0 and "== bridge tests: all " .. checks .. " checks pass =="
    or "== bridge tests: " .. failures .. " failure(s) of " .. checks .. " =="
)
os.exit(failures == 0 and 0 or 1)
