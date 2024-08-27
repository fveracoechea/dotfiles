{
  config,
  pkgs,
  ...
}: let
  background = "${config.home.homeDirectory}/dotfiles/wallpapers/forrest.png";
in {
  programs.rofi.enable = true;

  programs.waybar.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      "$mod" = "SUPER";
      # "$menu" = "wofi --show drun";

      "exec-once" = ''${pkgs.waybar}/bin/waybar'';
      "monitor" = ",highres,auto,auto";
    };
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [background];
      wallpaper = [", ${background}"];
    };
  };
}
