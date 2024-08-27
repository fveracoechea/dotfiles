{config, ...}: {
  programs.wofi.enable = true;

  programs.waybar.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      "$mod" = "SUPER";
    };
  };

  services.hyprpaper = let
    forrest = "${config.home.homeDirectory}/dotfiles/wallpapers/forrest.png";
  in {
    enable = true;
    settings = {
      preload = [forrest];
      wallpaper = [", ${forrest}"];
    };
  };
}
