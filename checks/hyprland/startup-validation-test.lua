local root, entry, mode = arg[1], arg[2], arg[3]
package.path = root .. "/checks/hyprland/?.lua;" .. package.path

local file = assert(io.open(entry))
local state = require("capture").run(file:read "*a", assert(entry:match "^(.*)/[^/]+$"))
file:close()

if mode == "invalid" then
  assert(#state.errors > 0 and state.errors[1]:find("bridge:", 1, true), "bridge error was not recorded")
  assert(
    #state.options == 0 and #state.binds == 0 and #state.monitors == 0,
    "invalid bridge applied compositor settings"
  )
  assert(#state.callbacks == 2, "invalid bridge registered user startup after the swallowed entry error")
  assert(#state.lifecycle["hyprland.start"] == 1, "invalid bridge launched user startup")
else
  assert(mode == "empty", "unknown test mode")
  assert(#state.errors == 0, table.concat(state.errors, "\n"))
  assert(#state.monitors == 0, "empty monitor array invented monitor declarations")
  assert(#state.binds == 46, "empty monitor array prevented configuration")
  assert(state.lifecycle["hyprland.start"][2] == "ultrashell", "valid entry did not register user startup")
end
assert(#state.lifecycle["hyprland.shutdown"] == 1, "Home Manager shutdown hook was lost")
print("Native startup validation passed: " .. mode)
