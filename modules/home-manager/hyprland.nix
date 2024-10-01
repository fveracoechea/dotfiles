{
  inputs,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    dunst
    libnotify
    hyprdim
  ];

  programs.wofi = {
    enable = true;
  };

  programs.waybar.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

    settings = let
      super = "SUPER";
      menu = "wofi --show drun";
      terminal = "kitty";
      browser = "chrome";
    in {
      "exec-once" = [
        "${pkgs.waybar}/bin/waybar"
        "hyprdim --no-dim-when-only --persist --ignore-leaving-special --dialog-dim"
      ];

      "monitor" = ",highres,auto,auto";

      bind =
        [
          "${super}, F, exec, firefox"
          "${super}, B, exec, ${browser}"
          "${super}, K, exec, ${terminal}"
          "${super}, A, exec, ${menu}"
          "${super} SHIFT, L, exec, hyprlock"
          ", Print, exec, grimblast copy area"
        ]
        ++ (
          # Workspaces: binds SUPER + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (builtins.genList (
              i: let
                ws = i + 1;
              in [
                "${super}, code:1${toString i}, workspace, ${toString ws}"
                "${super} SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            )
            9)
        );
    };
  };

  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 150;
          on-timeout = "brightnessctl set 0 --save && brightnessctl --device=tpacpi::kbd_backlight set 0 --save";
          on-resume = "brightnessctl --restore && brightnessctl --device=tpacpi::kbd_backlight --restore";
        }
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 380;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 1800;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  programs.hyprlock = {
    enable = true;

    # settings = {
    #   general = {
    #     hide_cursor = true;
    #     grace = 2;
    #   };
    #
    #   label = {
    #     text = "$USER";
    #     text_align = "center";
    #     font_size = 50;
    #     halign = "center";
    #     valign = "center";
    #   };
    #
    #   input-field = {
    #     size = "50, 50";
    #     placeholder_text = "<i>Input Password...</i> ";
    #   };
    # };
  };
}
