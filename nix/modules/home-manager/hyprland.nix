{
  config,
  pkgs,
  ...
}: {
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
        "$mod A, exec, rofi --show drun -show-icons"
      ];
    };
  };
}
