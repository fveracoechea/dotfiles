local json = require "lib.json"

local bridge = {}

local HEX_COLOR_PATTERN = "^#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$"

local function reject(message)
  return nil, "bridge: " .. message
end

local function valid_monitors(value)
  if not json.is_array(value) then
    return "monitors must be an array of strings"
  end
  local count, last = 0, 0
  for index, item in pairs(value) do
    if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > 64 then
      return "monitors must be an array with at most 64 entries"
    end
    if type(item) ~= "string" then
      return "monitors[" .. index .. "] must be a string"
    end
    if item == "" then
      return "monitors[" .. index .. "] must not be empty"
    end
    count = count + 1
    last = math.max(last, index)
  end
  if last ~= count then
    return "monitors must not have gaps"
  end
  return nil
end

local function valid_theme(value)
  if type(value) ~= "table" then
    return "theme must be an object"
  end
  for _, name in ipairs { "blue", "flamingo", "surface2" } do
    local color = value[name]
    if color == nil then
      return "theme." .. name .. " is required"
    end
    if type(color) ~= "string" or not color:match(HEX_COLOR_PATTERN) then
      return "theme." .. name .. " must be raw hex like #89b4fa"
    end
  end
  return nil
end

local function valid_paths(value)
  if type(value) ~= "table" then
    return "paths must be an object"
  end
  local cache = value.fuzzelCache
  if cache == nil then
    return "paths.fuzzelCache is required"
  end
  if type(cache) ~= "string" or cache == "" then
    return "paths.fuzzelCache must be a non-empty string"
  end
  if cache:sub(1, 1) ~= "/" then
    return "paths.fuzzelCache must be an absolute path"
  end
  return nil
end

function bridge.load(path)
  local file = io.open(path, "r")
  if not file then
    return reject("cannot open " .. path)
  end
  local content = file:read "*a"
  file:close()

  local ok, data = pcall(json.decode, content)
  if not ok then
    return reject("malformed JSON in " .. path .. ": " .. tostring(data))
  end
  if type(data) ~= "table" then
    return reject "bridge data must be a JSON object"
  end

  local err = valid_monitors(data.monitors)
  if err then
    return reject(err)
  end
  err = valid_theme(data.theme)
  if err then
    return reject(err)
  end
  err = valid_paths(data.paths)
  if err then
    return reject(err)
  end

  return data
end

function bridge.default_path()
  local xdg = os.getenv "XDG_CONFIG_HOME"
  if not xdg or xdg == "" then
    local home = os.getenv "HOME"
    if not home or home == "" then
      return nil, "bridge: neither XDG_CONFIG_HOME nor HOME is set"
    end
    xdg = home .. "/.config"
  end
  return xdg .. "/dotfiles/hyprland.json"
end

return bridge
