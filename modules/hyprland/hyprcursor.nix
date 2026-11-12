{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf config.dotfiles.hyprland.enable {
    home.pointerCursor = {
      enable = true;
      gtk.enable = true;
      x11.enable = true;
      hyprcursor.enable = true;

      size = 38;
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
    };
  };
}
