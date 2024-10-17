{
  lib,
  pkgs,
  ...
}: {
  programs.waybar = {
    enable = true;

    settings = let
      icon = size: icon: ''<span size="${size}">${icon}</span>'';
      largeIcon = icon "large";
      xlargeIcon = icon "x-large";
      format = icon: label: ''${largeIcon icon}    ${label}'';
      gFormat = icon: label: ''${largeIcon icon} ${label}'';
    in {
      mainBar = {
        layer = "top";
        position = "top";
        spacing = 8;
        margin-top = 12;
        margin-left = 12;
        margin-right = 12;

        "custom/apps" = {
          format = ''${largeIcon "󱄅"}  Apps'';
          on-click = "wofi --show drun --allow-images";
          tooltip-format = "App Launcher";
        };

        "custom/settings" = let
          settings = pkgs.gnome-control-center;
        in {
          format = xlargeIcon "";
          on-click = "env XDG_CURRENT_DESKTOP=gnome ${settings}/bin/gnome-control-center";
          tooltip-format = "System Settings";
        };

        "custom/nautilus" = {
          format = xlargeIcon "";
          on-click = "nautilus";
          tooltip-format = "Open File Manager";
        };

        "custom/chrome" = {
          format = xlargeIcon "";
          on-click = "google-chrome-stable";
          tooltip-format = "Google Chrome";
        };

        "custom/spotify" = {
          format = xlargeIcon "";
          on-click = "spotify";
          tooltip-format = "Spotify";
        };

        "custom/discord" = {
          format = xlargeIcon "";
          on-click = "vesktop";
          tooltip-format = "Discord";
        };

        "group/quick-links" = {
          orientation = "horizontal";
          modules = [
            "custom/settings"
            "custom/nautilus"
            "custom/chrome"
            "custom/spotify"
            "custom/discord"
          ];
        };

        cpu = {
          format = gFormat " " "{usage}%";
        };

        temperature = {
          format = gFormat "" "{temperatureC}󰔄";
        };

        memory = {
          format = gFormat " " "{used:0.1f}G/{total:0.1f}G";
        };

        disk = {
          format = gFormat " " "{percentage_free}%";
        };

        "group/stats" = {
          orientation = "horizontal";
          modules = [
            "cpu"
            "temperature"
            "memory"
            "disk"
          ];
        };

        pulseaudio = {
          scroll-step = 2;
          on-click = "pavucontrol";
          format = format "{icon}" "{volume}%";
          format-bluetooth = format "{icon}" "{volume}";
          format-muted = largeIcon "";
          format-icons = {
            "alsa_output.pci-0000_00_1f.3.analog-stereo" = "";
            "alsa_output.pci-0000_00_1f.3.analog-stereo-muted" = "";
            headphone = "";
            headset = "󰋎";
            phone = "";
            phone-muted = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
          };
        };

        bluetooth = {
          format = format "" "{status}";
          format-connected = format "" "{num_connections} connected";
          format-disabled = largeIcon "󰂲";
          format-off = largeIcon "󰂲";
          tooltip-format = "{controller_alias}\t{controller_address}";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          on-click = "blueman-manager";
        };

        network = {
          format-disconnected = format "󰖪" "0%";
          format-ethernet = format "" "100%";
          format-linked = "{ifname} (No IP)";
          format-wifi = format "" "{signalStrength}%";
          tooltip-format = "Connected to {essid} {ifname} via {gwaddr}";
          on-click = "nm-connection-editor";
        };

        "clock#time" = {
          format = format "󰥔" "{:%I:%M %p}";
          on-click = "gnome-calendar";
          tooltip = false;
        };

        "clock#date" = {
          format = format "" "{:%A %b %m}";
          on-click = "gnome-calendar";
          tooltip = false;
        };

        "hyprland/window" = {
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

          tray = {
            icon-size = 24;
            spacing = 8;
            show-passive-items = true;
          };

          persistent-workspaces = {
            "*" = 5;
          };
        };

        modules-left = [
          "custom/apps"
          "hyprland/window"
        ];

        modules-center = [
          "clock#time"
          "clock#date"
          "network"
          "pulseaudio"
          "hyprland/workspaces"
          "group/stats"
          "tray"
          "gamemode"
        ];

        modules-right = [
          "group/quick-links"
        ];
      };
    };

    style = ''
      ${lib.fileContents ../../config/waybar/catppuccin.css}
      ${lib.fileContents ../../config/waybar/styles.css}
    '';
  };

  stylix.targets.waybar.enable = false;
}
