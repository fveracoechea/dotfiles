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
expect_reject("sparse-monitors.json", "sparse monitor object")
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

print "== strict decoder grammar =="
expect_reject("trailing-comma.json", "trailing comma")
expect_reject("invalid-number.json", "invalid JSON number in extra field")
expect_reject("invalid-unicode.json", "invalid unicode in monitor string")
do
  local json = require "lib.json"
  for _, text in ipairs {
    "[1,]",
    '{"x":1,}',
    "01",
    "-01",
    "0x10",
    "1.",
    "-.1",
    "1e",
    "1e+",
    "1e9999",
    "[1,,2]",
    '{"a":null,"a":1}',
    "true false",
    '"\\uZ1234"',
    '"\\u123"',
    '"\\uD800"',
    '"\\uDC00"',
    '"\\uD800\\u0041"',
    '"\\x20"',
    '"unterminated',
    '"' .. string.char(0) .. '"',
    '"' .. string.char(0xc0, 0x80) .. '"',
    '"' .. string.char(0xed, 0xa0, 0x80) .. '"',
  } do
    assert_true(not pcall(json.decode, text), "malformed JSON rejected: " .. string.format("%q", text))
  end
  for _, text in ipairs { "0", "-0", "1.25", "-1.25e+2", "1E-2", "[]", "{}", "[true,false,null]" } do
    assert_true(pcall(json.decode, text), "valid JSON accepted: " .. text)
  end
  assert_true(json.decode '"\\uD83D\\uDE00"' == utf8.char(0x1f600), "surrogate pair decoded")
  assert_true(json.decode '"\\u0041"' == "A", "BMP escape decoded")
  assert_true(json.decode '"\\\\u0041"' == "\\u0041", "escaped backslash is not a unicode escape")
  assert_true(json.decode('"' .. utf8.char(0x1f600) .. '"') == utf8.char(0x1f600), "raw UTF-8 preserved")
  assert_true(json.encode(json.null) == "null", "null sentinel round trips")
end
do
  -- The vendored decoder preserves JSON null
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
