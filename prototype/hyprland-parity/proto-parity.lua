-- PROTOTYPE for issue 32. Throwaway. Run with Lua 5.5:
--
--   lua proto-parity.lua <repo-root>
--
-- What it proves (and does not prove) is in README.md next to this file.
--
-- Pipeline demonstrated:
--   live baseline binds.json (Lua 5.5 + vendored rxi/json.lua decode)
--     -> canonical records
--     -> ordered positional diff against a fixed hand-written expected subset
--     -> negative mutation checks: order, arg, flag, description, missing

local function script_dir()
  local src = debug.getinfo(1, "S").source:sub(2)
  return src:match("^(.*)/") or "."
end

local here = script_dir()
local root = arg[1] or here .. "/../.."
local baseline = root .. "/docs/research/hyprland-live-baseline"

local json = dofile(here .. "/vendor/json.lua")

local function read(path)
  local f = assert(io.open(path, "r"))
  local data = f:read("*a")
  f:close()
  return data
end

-- Gate 0: the vendored decoder reads the real baseline on Lua 5.5.
local binds = json.decode(read(baseline .. "/hyprctl/binds.json"))
assert(#binds == 46, "expected 46 live binds, got " .. #binds)

-- Canonicalize one binds.json entry into the record shape both sides share.
local FLAG_KEYS = { "locked", "mouse", "release", "repeat", "longPress",
  "non_consuming", "auto_consuming", "has_description" }

local function canonical(entry)
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
    dispatcher = entry.dispatcher,
    arg = entry.arg,
    flags = flags,
  }
end

local function eq(a, b)
  if a.modmask ~= b.modmask then return false, "modmask" end
  if a.key ~= b.key then return false, "key" end
  if a.keycode ~= b.keycode then return false, "keycode" end
  if a.submap ~= b.submap then return false, "submap" end
  if a.catch_all ~= b.catch_all then return false, "catch_all" end
  if a.description ~= b.description then return false, "description" end
  if a.dispatcher ~= b.dispatcher then return false, "dispatcher" end
  if a.arg ~= b.arg then return false, "arg" end
  for _, k in ipairs(FLAG_KEYS) do
    if a.flags[k] ~= b.flags[k] then return false, "flag " .. k end
  end
  return true
end

local function describe(r)
  return string.format("mod=%d key=%s kc=%d submap=%q catch_all=%s desc=%q dsp=%s arg=%q",
    r.modmask, r.key, r.keycode, r.submap, tostring(r.catch_all),
    r.description, r.dispatcher, r.arg)
end

local expected = dofile(here .. "/proto-expected.lua")

local failures = 0

-- Positive: every expected record matches the live baseline at its position.
print("== fixed expected subset vs live baseline (ordered, positional) ==")
for _, e in ipairs(expected) do
  local live = canonical(assert(binds[e.index], "no live bind at index " .. e.index))
  local same, field = eq(e.record, live)
  if same then
    print(string.format("  ok   #%02d %s", e.index, describe(e.record)))
  else
    failures = failures + 1
    print(string.format("  FAIL #%02d differs in %s\n    expected: %s\n    live:     %s",
      e.index, field, describe(e.record), describe(live)))
  end
end

-- Negative: each mutation must be detected. A comparator that lets any of
-- these through would reduce parity to a count.
local function clone_expected()
  local out = {}
  for _, e in ipairs(expected) do
    local rec = {}
    for k, v in pairs(e.record) do rec[k] = v end
    local flags = {}
    for k, v in pairs(e.record.flags) do flags[k] = v end
    rec.flags = flags
    table.insert(out, { index = e.index, record = rec })
  end
  return out
end

local function compare_mutation(mutated, label)
  local scope = {}
  for _, e in ipairs(expected) do scope[e.index] = true end
  for _, e in ipairs(mutated) do scope[e.index] = nil end
  for idx in pairs(scope) do
    print(string.format("  ok   detected: %s (index %d left uncovered)", label, idx))
    return true
  end
  for _, e in ipairs(mutated) do
    local live = canonical(binds[e.index])
    if not eq(e.record, live) then
      print(string.format("  ok   detected: %s", label))
      return true
    end
  end
  failures = failures + 1
  print(string.format("  FAIL not detected: %s", label))
  return false
end

print("== negative mutations (each must be detected) ==")

-- 1. order swap between the two SUPER,J records: same records, registered
--    in the opposite order. Positions stay fixed; only records move.
do
  local m = clone_expected()
  m[1].record, m[4].record = m[4].record, m[1].record
  compare_mutation(m, "order swap of the two SUPER+J binds")
end

-- 2. argument change: fullscreenstate "0 2" -> "0 1"
do
  local m = clone_expected()
  m[3].record.arg = "0 1"
  compare_mutation(m, "fullscreenstate arg changed to '0 1'")
end

-- 3. flag flip: mouse=true on a keyboard bind
do
  local m = clone_expected()
  m[5].record.flags.mouse = true
  compare_mutation(m, "flag flip: mouse=true on the Copy bind")
end

-- 4. description change on the last record
do
  local m = clone_expected()
  m[6].record.description = "Move window"
  m[6].record.flags.has_description = true
  compare_mutation(m, "mouse bind description changed")
end

-- 5. missing record: drop the fullscreenstate bind entirely
do
  local m = clone_expected()
  table.remove(m, 3)
  compare_mutation(m, "missing record: fullscreenstate bind dropped")
end

-- 6. trailing comma dropped on the layoutmsg arg (normalization trap:
--    the live parser keeps "togglesplit," verbatim)
do
  local m = clone_expected()
  m[1].record.arg = "togglesplit"
  compare_mutation(m, "trailing comma dropped from layoutmsg arg")
end

-- 7. submap change: the current baseline has only "" submaps, but a config
--    that registers a bind inside a submap must be caught
do
  local m = clone_expected()
  m[1].record.submap = "resize"
  compare_mutation(m, "bind moved into submap 'resize'")
end

-- 8. keycode bind: key as raw keycode instead of keysym
do
  local m = clone_expected()
  m[1].record.keycode = 36
  compare_mutation(m, "keycode 36 recorded instead of keysym")
end

-- 9. catch_all bind
do
  local m = clone_expected()
  m[1].record.catch_all = true
  compare_mutation(m, "catch_all flipped to true")
end

print(failures == 0
  and "== prototype comparator: all checks pass =="
  or "== prototype comparator: " .. failures .. " failure(s) ==")
os.exit(failures == 0 and 0 or 1)
