-- PROTOTYPE for issue 32. Throwaway. The production harness (issue 36)
-- builds its stub from share/hypr/stubs/hl.meta.lua instead.
--
-- Generic recording stub for the Hyprland Lua API. Every call is recorded
-- as { path = "bind" | "config" | "dsp.window.close" | ..., args = {...} }.
-- Dispatcher objects are proxies that remember their dotted path.

local log = {}

local function dispatcher_proxy(partial)
  return setmetatable({}, {
    __index = function(_, name)
      return dispatcher_proxy(partial .. "." .. name)
    end,
    __call = function(_, ...)
      table.insert(log, { path = partial, args = { ... } })
      return dispatcher_proxy(partial)
    end,
    __tostring = function() return "dsp:" .. partial end,
  })
end

local function call_proxy(path)
  return setmetatable({}, {
    __call = function(_, ...)
      table.insert(log, { path = path, args = { ... } })
      return dispatcher_proxy(path)
    end,
    __index = function(_, name)
      return call_proxy(path .. "." .. name)
    end,
  })
end

local hl = call_proxy("hl")

-- Hyprland calls hl.set_option / hl.config style surfaces through the same
-- call proxy; nothing is special-cased here on purpose: the stub records
-- everything and the comparator decides what matters.

return {
  hl = hl,
  log = log,
}
