local bridge = require "bridge"
local data = assert(bridge.load(assert(bridge.default_path())))

require("modules.settings").apply(data)
require("modules.env").apply()
require("modules.bindings").apply(data)
require("modules.windowrules").apply()
require("modules.theme").apply(data)

return true
