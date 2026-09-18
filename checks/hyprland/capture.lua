-- Execute trusted configuration with no host process execution or file writes.
-- This is a recording environment, not a security boundary for hostile Lua.
local stub = require "hl-stub"
local capture = {}

function capture.run(source, directory, chunkname)
  local hl, state = stub.new()
  state.errors = {}
  local phase = "config"
  state.lifecycle = { ["hyprland.start"] = {}, ["hyprland.shutdown"] = {} }
  local function copy_table(value)
    local out = {}
    for k, v in pairs(value) do
      out[k] = v
    end
    return out
  end
  local blocked
  local function reject(message)
    blocked = message
    error("capture: " .. message, 2)
  end
  local arity = {
    bind = 3,
    config = 1,
    define_submap = 2,
    env = 2,
    monitor = 1,
    window_rule = 1,
    workspace_rule = 1,
    on = 2,
    exec_cmd = 1,
  }
  local recorded_hl = setmetatable({ dsp = hl.dsp }, {
    __index = function(_, name)
      reject("unsupported hl operation " .. tostring(name))
    end,
  })
  for name, count in pairs(arity) do
    recorded_hl[name] = function(...)
      if select("#", ...) > count then
        reject("unsupported arguments to hl." .. name)
      end
      if phase ~= "config" and name ~= "exec_cmd" then
        reject "only commands are supported in lifecycle callbacks"
      end
      local ok, result = pcall(hl[name], ...)
      if not ok then
        reject(result)
      end
      if phase ~= "config" then
        table.insert(state.lifecycle[phase], table.remove(state.exec))
      end
      return result
    end
  end
  local env = {
    assert = assert,
    error = error,
    ipairs = ipairs,
    pairs = pairs,
    next = next,
    pcall = pcall,
    select = select,
    tonumber = tonumber,
    tostring = tostring,
    type = type,
    setmetatable = setmetatable,
    getmetatable = getmetatable,
    math = copy_table(math),
    string = copy_table(string),
    table = copy_table(table),
    utf8 = copy_table(utf8),
    hl = recorded_hl,
    package = { path = directory .. "/?.lua" },
    os = {
      getenv = os.getenv,
      execute = function(command, ...)
        if select("#", ...) > 0 then
          reject "extra os.execute arguments"
        end
        recorded_hl.exec_cmd(command)
        return true, "exit", 0
      end,
    },
    io = {
      open = function(path, mode)
        if mode ~= nil and mode ~= "r" and mode ~= "rb" then
          reject "file writes are unsupported"
        end
        return io.open(path, mode)
      end,
    },
  }
  env._G = env
  for _, library in ipairs { env.os, env.io, env.package } do
    setmetatable(library, {
      __index = function(_, name)
        reject("unsupported library operation " .. tostring(name))
      end,
    })
  end
  local loaded = {}
  local function run_file(path)
    if path:sub(1, #directory + 1) ~= directory .. "/" or path:find("..", 1, true) then
      reject "Lua files must be inside the staged config directory"
    end
    local fn, err = loadfile(path, "t", env)
    if not fn then
      reject(err)
    end
    return fn()
  end
  env.dofile = run_file
  env.require = function(name)
    if type(name) ~= "string" or not name:match "^[%w_%-]+[.%w_%-]*$" or name:find("..", 1, true) then
      reject "invalid module name"
    end
    if loaded[name] ~= nil then
      return loaded[name]
    end
    loaded[name] = true
    local ok, value = pcall(run_file, directory .. "/" .. name:gsub("%.", "/") .. ".lua")
    if not ok then
      -- Hyprland 0.55.4 safeLuaRequire records execution errors and caches {}.
      table.insert(state.errors, tostring(value))
      value = {}
    end
    loaded[name] = value == nil and true or value
    return loaded[name]
  end
  assert(load(source, chunkname or "staged config", "t", env))()
  for _, event in ipairs { "hyprland.start", "hyprland.shutdown" } do
    phase = event
    for _, callback in ipairs(state.callbacks) do
      if callback.event == event then
        callback.fn()
      end
    end
  end
  if blocked then
    error("capture: " .. blocked, 2)
  end
  return state
end

return capture
