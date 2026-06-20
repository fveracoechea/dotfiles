{
  lib,
  config,
  ...
}: let
  toRgb = color: "rgb(${lib.substring 1 6 (lib.strings.toLower color)})";
  p = config.dotfiles.palette;
  theme = {
    flamingo = toRgb p.flamingo;
    blue = toRgb p.blue;
    surface2 = toRgb p.surface2;
  };
in {
  config = lib.mkIf config.dotfiles.hyprland.enable {
    wayland.windowManager.hyprland.settings = {
      general = {
        "col.active_border" = "${theme.blue} ${theme.flamingo} 90deg";
        "col.inactive_border" = theme.surface2;
      };
    };
  };
}
