{
  inputs,
  pkgs,
  ...
}: {
  xdg.desktopEntries."org.gnome.Settings" = {
    name = "Settings";
    comment = "Gnome Control Center";
    icon = "org.gnome.Settings";
    exec = "env XDG_CURRENT_DESKTOP=gnome ${pkgs.gnome.gnome-control-center}/bin/gnome-control-center";
    categories = ["X-Preferences"];
    terminal = false;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

    settings = let
      super = "SUPER";
      menu = "wofi --show drun --allow-images";
      terminal = "kitty";
      browser = "google-chrome-stable";
    in {
      env = [
        "BROWSER,${browser}"
        "XDG_CURRENT_DESKTOP,Hyprland"
      ];

      misc = {
        vrr = 2;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
      };

      exec-once = [
        "${pkgs.waybar}/bin/waybar"
        "hyprdim --no-dim-when-only --persist --ignore-leaving-special --dialog-dim"
      ];

      monitor = ["DP-1,preferred,auto,auto"];

      general = {
        border_size = 2;
        gaps_in = 8;
        gaps_out = 16;
      };

      decoration = {
        rounding = 5;
        drop_shadow = true;
        blur.enabled = true;
      };

      master = {
        allow_small_split = true;
        mfact = 0.32;
        new_on_top = false;
      };

      binds = {
        allow_workspace_cycles = true;
      };

      layerrule = [
        "blur,notifications"
      ];

      windowrule = let
        f = regex: "float, ^(${regex})$";
      in [
        (f "org.gnome.Calculator")
        (f "pavucontrol")
        (f "nm-connection-editor")
        (f "org.gnome.Settings")
        (f "xdg-desktop-portal")
        (f "xdg-desktop-portal-gnome")
      ];

      bindm = [
        "SHIFT_ALT, mouse:272, movewindow"
        "SHIFT_ALT, mouse:273, resizewindow"
      ];

      bind =
        [
          "${super}, F, exec, firefox"
          "${super}, B, exec, ${browser}"
          "${super}, T, exec, ${terminal}"
          "${super}, A, exec, ${menu}"
          "${super}, Q, killactive"
          "${super}_ALT, Q, exit"
          "${super}_ALT, L, exec, hyprlock"

          ", Print, exec, grimblast copy area"

          "${super}, H, movefocus, l"
          "${super}, L, movefocus, r"
          "${super}, K, movefocus, u"
          "${super}, J, movefocus, d"
        ]
        ++ (
          # Workspaces:
          # binds SUPER + {1..5} to workspace {1..5}
          # binds SUPER + ATL + {1..5} to move workspace {1..5}
          builtins.concatLists (builtins.genList (
              i: let
                ws = i + 1;
              in [
                "${super}, ${toString ws}, workspace, ${toString ws}"
                "${super}_ALT, ${toString ws}, movetoworkspace, ${toString ws}"
              ]
            )
            5)
        );
    };
  };

  services.hypridle = {
    enable = true;

    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        lock_cmd = "hyprlock";
      };

      listener = [
        {
          timeout = 900;
          on-timeout = "hyprlock";
        }
        {
          timeout = 1200;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  programs.hyprlock = {
    enable = true;

    settings = {
      disable_loading_bar = true;
      grace = 300;

      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      input-field = [
        {
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(202, 211, 245)";
          inner_color = "rgb(91, 96, 120)";
          outer_color = "rgb(24, 25, 38)";
          outline_thickness = 5;
          placeholder_text = ''<span foreground="##cad3f5">Password...</span>'';
          shadow_passes = 2;
        }
      ];
    };
  };
}
