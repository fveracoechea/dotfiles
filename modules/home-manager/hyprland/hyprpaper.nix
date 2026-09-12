{
  lib,
  config,
  pkgs-stable,
  ...
}: let
  monitor = "DP-1";
  wallpaper = "${config.home.homeDirectory}/dotfiles/assets/wallpapers/yellow-mountains.png";
in {
  config = lib.mkIf config.dotfiles.hyprland.enable {
    services.hyprpaper = {
      enable = true;
      # Release Channel: tracks the compositor. See ADR-0007.
      package = pkgs-stable.hyprpaper;
      settings = {
        preload = [wallpaper];
        wallpaper = [
          {
            inherit monitor;
            path = wallpaper;
          }
        ];
      };
    };
  };
}
