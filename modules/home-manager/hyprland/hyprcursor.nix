{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf config.dotfiles.hyprland.enable {
    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      hyprcursor.enable = true;

      size = 38;
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
    };
  };
}
