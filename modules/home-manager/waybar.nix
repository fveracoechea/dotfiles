{lib, ...}: {
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        # margin-left = 16;
        # margin-top = 16;
        # margin-right = 16;
        # margin-bottom = 0;
        spacing = 16;

        modules-left = [
          "custom/apps"
          "group/quick-links"
          "hyprland/workspaces"
        ];

        modules-center = [
          "hyprland/window"
        ];

        modules-right = [
          "pulseaudio"
          "bluetooth"
          "network"
          # "group/hardware"
          # "group/tools"
          # "tray"
          # "custom/exit"
          "clock"
        ];

        "custom/apps" = {
          format = "󱄅";
          on-click = "wofi --show drun --allow-images";
          tooltip-format = "App Launcher";
        };

        "custom/nautilus" = {
          format = "󰉋";
          on-click = "nautilus";
          tooltip-format = "Open file manager";
        };

        "custom/chrome" = {
          format = "󰊯";
          on-click = "google-chrome-stable";
          tooltip-format = "Google Chrome";
        };

        "group/quick-links" = {
          orientation = "horizontal";
          modules = [
            "custom/nautilus"
            "custom/chrome"
          ];
        };

        "hyprland/window" = {
          icon = true;
          icon-size = 22;
          separate-outputs = true;
          rewrite = {
            "(.*) - Google Chrome" = "$1";
          };
        };

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
      };
    };

    style = ''
      ${lib.fileContents ../../config/waybar/catppuccin.css}
      ${lib.fileContents ../../config/waybar/styles.css}
    '';
  };

  stylix.targets.waybar.enable = false;
}
