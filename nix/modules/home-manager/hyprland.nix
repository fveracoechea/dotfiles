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
      "$menu" = "rofi --show drun -show-icons";

      "exec-once" = ''${pkgs.waybar}/bin/waybar'';
      "monitor" = ",highres,auto,auto";

      bindm = [
        "$mod, A, exec, rofi --show drun -show-icons"
      ];
    };
  };

  services.hyprpaper.enable = true;
}
