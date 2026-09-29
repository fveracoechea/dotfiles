local config_home = os.getenv "XDG_CONFIG_HOME"
if not config_home or config_home == "" then
  config_home = assert(os.getenv "HOME") .. "/.config"
end

dofile(config_home .. "/hypr/settings.lua")
dofile(config_home .. "/hypr/windowrule.lua")
dofile(config_home .. "/hypr/bindings.lua")

hl.on("hyprland.start", function()
  if os.getenv "UWSM_FINALIZE_VARNAMES" then
    hl.exec_cmd "uwsm finalize HYPRLAND_INSTANCE_SIGNATURE"
  end
end)
