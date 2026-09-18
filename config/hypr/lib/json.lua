--
-- json.lua
--
-- Copyright (c) 2019 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local json = { _version = "0.1.2" }
local container_types = setmetatable({}, { __mode = "k" })

function json.is_array(value)
  return container_types[value] == "array"
end

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode

local escape_char_map = {
  ["\\"] = "\\\\",
  ['"'] = '\\"',
  ["\b"] = "\\b",
  ["\f"] = "\\f",
  ["\n"] = "\\n",
  ["\r"] = "\\r",
  ["\t"] = "\\t",
}

local escape_char_map_inv = { ["\\/"] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end

local function escape_char(c)
  return escape_char_map[c] or string.format("\\u%04x", c:byte())
end

local function encode_nil(val)
  return "null"
end

local function encode_table(val, stack)
  local res = {}
  stack = stack or {}

  -- Circular reference?
  if stack[val] then
    error "circular reference"
  end

  stack[val] = true

  if json.is_array(val) or (container_types[val] == nil and (rawget(val, 1) ~= nil or next(val) == nil)) then
    -- Treat as array -- check keys are valid and it is not sparse
    local n = 0
    for k in pairs(val) do
      if type(k) ~= "number" then
        error "invalid table: mixed or invalid key types"
      end
      n = n + 1
    end
    if n ~= #val then
      error "invalid table: sparse array"
    end
    -- Encode
    for i, v in ipairs(val) do
      table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"
  else
    -- Treat as an object
    for k, v in pairs(val) do
      if type(k) ~= "string" then
        error "invalid table: mixed or invalid key types"
      end
      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
  end
end

local function encode_string(val)
  return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end

local function encode_number(val)
  -- Check for NaN, -inf and inf
  if val ~= val or val <= -math.huge or val >= math.huge then
    error("unexpected number value '" .. tostring(val) .. "'")
  end
  return string.format("%.14g", val)
end

local type_func_map = {
  ["nil"] = encode_nil,
  ["table"] = encode_table,
  ["string"] = encode_string,
  ["number"] = encode_number,
  ["boolean"] = tostring,
}

encode = function(val, stack)
  if val == json.null then
    return "null"
  end
  local t = type(val)
  local f = type_func_map[t]
  if f then
    return f(val, stack)
  end
  error("unexpected type '" .. t .. "'")
end

function json.encode(val)
  return (encode(val))
end

-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
  local res = {}
  for i = 1, select("#", ...) do
    res[select(i, ...)] = true
  end
  return res
end

local space_chars = create_set(" ", "\t", "\r", "\n")
local delim_chars = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local literals = create_set("true", "false", "null")

-- Local changes to rxi/json.lua v0.1.2: preserve null and container types; enforce JSON number,
-- comma and string grammar; validate UTF-8 and surrogate pairs; reject
-- duplicate object keys and non-finite numbers. See ../README.md.
json.null = setmetatable({}, {
  __tostring = function()
    return "json.null"
  end,
})

local literal_map = {
  ["true"] = true,
  ["false"] = false,
  ["null"] = json.null,
}

local function next_char(str, idx, set, negate)
  for i = idx, #str do
    if set[str:sub(i, i)] ~= negate then
      return i
    end
  end
  return #str + 1
end

local function decode_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if str:sub(i, i) == "\n" then
      line_count = line_count + 1
      col_count = 1
    end
  end
  error(string.format("%s at line %d col %d", msg, line_count, col_count))
end

local function parse_string(str, i)
  local out, j = {}, i + 1
  local function read_hex(at)
    local hex = str:sub(at, at + 3)
    if not hex:match "^%x%x%x%x$" then
      decode_error(str, at, "invalid unicode escape")
    end
    return tonumber(hex, 16)
  end
  while j <= #str do
    local byte = str:byte(j)
    if byte < 32 then
      decode_error(str, j, "control character in string")
    end
    if byte == 34 then
      return table.concat(out), j + 1
    elseif byte == 92 then
      local escape = str:sub(j, j + 1)
      if escape == "\\u" then
        local cp = read_hex(j + 2)
        j = j + 6
        if cp >= 0xd800 and cp <= 0xdbff then
          if str:sub(j, j + 1) ~= "\\u" then
            decode_error(str, j, "missing low surrogate")
          end
          local low = read_hex(j + 2)
          if low < 0xdc00 or low > 0xdfff then
            decode_error(str, j, "invalid low surrogate")
          end
          cp = 0x10000 + (cp - 0xd800) * 0x400 + low - 0xdc00
          j = j + 6
        elseif cp >= 0xdc00 and cp <= 0xdfff then
          decode_error(str, j - 6, "unexpected low surrogate")
        end
        out[#out + 1] = utf8.char(cp)
      else
        local decoded = escape_char_map_inv[escape]
        if not decoded then
          decode_error(str, j, "invalid escape")
        end
        out[#out + 1] = decoded
        j = j + 2
      end
    else
      out[#out + 1] = str:sub(j, j)
      j = j + 1
    end
  end
  decode_error(str, i, "expected closing quote for string")
end

local function parse_number(str, i)
  local x = next_char(str, i, delim_chars)
  local s = str:sub(i, x - 1)
  local pos = s:sub(1, 1) == "-" and 2 or 1
  local function digits()
    local start = pos
    while s:sub(pos, pos):match "^[0-9]$" do
      pos = pos + 1
    end
    return pos > start
  end
  local valid
  if s:sub(pos, pos) == "0" then
    pos = pos + 1
    valid = true
  else
    valid = digits()
  end
  if s:sub(pos, pos) == "." then
    pos = pos + 1
    valid = digits() and valid
  end
  if s:sub(pos, pos):match "^[eE]$" then
    pos = pos + 1
    if s:sub(pos, pos):match "^[+-]$" then
      pos = pos + 1
    end
    valid = digits() and valid
  end
  local n = tonumber(s)
  if not valid or pos <= #s or not n or math.abs(n) == math.huge then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end
  return n, x
end

local function parse_literal(str, i)
  local x = next_char(str, i, delim_chars)
  local word = str:sub(i, x - 1)
  if not literals[word] then
    decode_error(str, i, "invalid literal '" .. word .. "'")
  end
  return literal_map[word], x
end

local function parse_array(str, i)
  local res = {}
  container_types[res] = "array"
  local n = 1
  i = i + 1
  while 1 do
    local x
    i = next_char(str, i, space_chars, true)
    -- Empty / end of array?
    if str:sub(i, i) == "]" then
      i = i + 1
      break
    end
    -- Read token
    x, i = parse(str, i)
    res[n] = x
    n = n + 1
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "]" then
      break
    end
    if chr ~= "," then
      decode_error(str, i, "expected ']' or ','")
    end
    if str:sub(next_char(str, i, space_chars, true), next_char(str, i, space_chars, true)) == "]" then
      decode_error(str, i, "trailing comma")
    end
  end
  return res, i
end

local function parse_object(str, i)
  local res = {}
  container_types[res] = "object"
  i = i + 1
  while 1 do
    local key, val
    i = next_char(str, i, space_chars, true)
    -- Empty / end of object?
    if str:sub(i, i) == "}" then
      i = i + 1
      break
    end
    -- Read key
    if str:sub(i, i) ~= '"' then
      decode_error(str, i, "expected string for key")
    end
    key, i = parse(str, i)
    -- Read ':' delimiter
    i = next_char(str, i, space_chars, true)
    if str:sub(i, i) ~= ":" then
      decode_error(str, i, "expected ':' after key")
    end
    i = next_char(str, i + 1, space_chars, true)
    -- Read value
    val, i = parse(str, i)
    -- Set
    if res[key] ~= nil then
      decode_error(str, i, "duplicate object key")
    end
    res[key] = val
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "}" then
      break
    end
    if chr ~= "," then
      decode_error(str, i, "expected '}' or ','")
    end
    if str:sub(next_char(str, i, space_chars, true), next_char(str, i, space_chars, true)) == "}" then
      decode_error(str, i, "trailing comma")
    end
  end
  return res, i
end

local char_func_map = {
  ['"'] = parse_string,
  ["0"] = parse_number,
  ["1"] = parse_number,
  ["2"] = parse_number,
  ["3"] = parse_number,
  ["4"] = parse_number,
  ["5"] = parse_number,
  ["6"] = parse_number,
  ["7"] = parse_number,
  ["8"] = parse_number,
  ["9"] = parse_number,
  ["-"] = parse_number,
  ["t"] = parse_literal,
  ["f"] = parse_literal,
  ["n"] = parse_literal,
  ["["] = parse_array,
  ["{"] = parse_object,
}

parse = function(str, idx)
  local chr = str:sub(idx, idx)
  local f = char_func_map[chr]
  if f then
    return f(str, idx)
  end
  decode_error(str, idx, "unexpected character '" .. chr .. "'")
end

function json.decode(str)
  if type(str) ~= "string" then
    error("expected argument of type string, got " .. type(str))
  end
  local valid, at = utf8.len(str)
  if not valid then
    decode_error(str, at, "invalid UTF-8")
  end
  local res, idx = parse(str, next_char(str, 1, space_chars, true))
  idx = next_char(str, idx, space_chars, true)
  if idx <= #str then
    decode_error(str, idx, "trailing garbage")
  end
  return res
end

return json
