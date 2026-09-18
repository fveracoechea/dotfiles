if require "entry" ~= true then
  return
end

hl.on("hyprland.start", function()
  hl.exec_cmd "ultrashell"
end)
