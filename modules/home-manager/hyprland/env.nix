{
  lib,
  config,
  ...
}: let
  browser = "google-chrome-stable";
in {
  config = lib.mkIf config.dotfiles.hyprland.enable {
    wayland.windowManager.hyprland.settings = {
      env = [
        "BROWSER,${browser}"

        # FORCE ALL APPS TO USE WAYLAND
        "GDK_BACKEND,wayland,x11,*"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_STYLE_OVERRIDE,kvantum"
        "SDL_VIDEODRIVER,wayland"
        "MOZ_ENABLE_WAYLAND,1"
        "ELECTRON_OZONE_PLATFORM_HINT,wayland"
        "OZONE_PLATFORM,wayland"
        "XDG_SESSION_TYPE,wayland"

        # BETTER DPI SCALING FOR QT APPS
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_QPA_PLATFORMTHEME,qt6ct"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"

        # ALLOW BETTER SUPPORT FOR SCREEN SHARING (GOOGLE MEET, DISCORD, ETC)
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"

        # CURSOR SIZE
        "XCURSOR_SIZE,38"
        "HYPRCURSOR_SIZE,38"
      ];

      ecosystem = {
        no_update_news = true;
      };

      xwayland = {
        force_zero_scaling = true;
      };
    };
  };
}
