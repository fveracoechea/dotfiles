{lib, ...}: {
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        margin-left = 16;
        margin-top = 16;
        margin-right = 16;
        margin-bottom = 0;
        spacing = 8;

        modules-left = [
          "custom/appmenu"
          "group/settings"
          "hyprland/window"
          "custom/empty"
        ];

        modules-center = [
          "hyprland/workspaces"
        ];

        modules-right = [
          "custom/updates"
          "pulseaudio"
          "bluetooth"
          "battery"
          "network"
          "group/hardware"
          "group/tools"
          "tray"
          "custom/exit"
          "clock"
        ];

        "hyprland/workspaces" = {
          on-scroll-up = "hyprctl dispatch workspace r-1";
          on-scroll-down = "hyprctl dispatch workspace r+1";
          on-click = "activate";
          active-only = false;
          all-outputs = true;
          format = "{}";
          format-icons = {
            "urgent" = "";
            "active" = "";
            "default" = "";
          };

          persistent-workspaces = {
            "*" = 5;
          };
        };

        "custom/empty" = {
          format = "";
        };

        "custom/settings" = {
          format = "";
          on-click = "com.ml4w.dotfilessettings";
          tooltip-format = "ML4W Dotfiles Settings";
        };
      };
    };

    style = ''
      ${lib.fileContents ../../config/waybar/catppuccin.css}
      ${lib.fileContents ../../config/waybar/styles.css}
    '';
  };

  stylix.targets.waybar.enable = false;
}
