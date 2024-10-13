{
  lib,
  pkgs,
  ...
}: {
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
          "network"
          "pulseaudio"
          "tray"
          "bluetooth"
          "clock"
        ];

        "custom/apps" = {
          format = "󱄅";
          on-click = "wofi --show drun --allow-images";
          tooltip-format = "App Launcher";
        };

        "custom/settings" = let
          settings = pkgs.gnome.gnome-control-center;
        in {
          format = "󰒓";
          on-click = "env XDG_CURRENT_DESKTOP=gnome ${settings}/bin/gnome-control-center";
          tooltip-format = "System Settings";
        };

        "custom/nautilus" = {
          format = "󰉋";
          on-click = "nautilus";
          tooltip-format = "Open File Manager";
        };

        "custom/chrome" = {
          format = "";
          on-click = "google-chrome-stable";
          tooltip-format = "Google Chrome";
        };

        "custom/pipewire" = {};

        "group/quick-links" = {
          orientation = "horizontal";
          modules = [
            "custom/settings"
            "custom/nautilus"
            "custom/chrome"
          ];
        };

        pulseaudio = {
          format = "{volume}% {icon}";
          format-bluetooth = "{volume}% {icon}";
          format-muted = "";
          format-icons = {
            "alsa_output.pci-0000_00_1f.3.analog-stereo" = "";
            "alsa_output.pci-0000_00_1f.3.analog-stereo-muted" = "";
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            phone-muted = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
            ];
          };
          scroll-step = 1;
          on-click = "pavucontrol";
          ignored-sinks = [
            "Easy Effects Sink"
          ];
        };

        network = {
          format-disconnected = "󰖪  0%";
          format-ethernet = "󰈀 100%";
          format-linked = "{ifname} (No IP)";
          format-wifi = "   {signalStrength}%";
          tooltip-format = "Connected to {essid} {ifname} via {gwaddr}";
          on-click = "env XDG_CURRENT_DESKTOP=gnome nm-applet";
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
