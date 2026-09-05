{
  lib,
  config,
  ...
}: let
  persistentWorkspaces = [1 2 3 4 5];
in {
  config = lib.mkIf config.dotfiles.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;
      # set the Hyprland and XDPH packages to null to use the ones from the NixOS module
      package = null;
      portalPackage = null;

      # Set explicitly, not left to the default: the module flips its default
      # to "lua" at `home.stateVersion` 26.05, and the compositor is held at
      # 0.55.4 for hyprlang. A stray `hyprland.lua` also wins over
      # `hyprland.conf`, so the two must never disagree.
      configType = "hyprlang";

      settings = {
        monitor = config.dotfiles.hyprland.monitors;

        cursor = {
          enable_hyprcursor = false;
        };

        misc = {
          vrr = 2;
          animate_manual_resizes = true;
          animate_mouse_windowdragging = true;
        };

        exec-once = [
          "ultrashell"
        ];

        general = {
          layout = "dwindle";
          border_size = 3;
          resize_on_border = true;
          gaps_in = 10;
          gaps_out = "10,18,18,18";
        };

        layout = {
          # Avoid overly wide single-window layouts on wide screens
          single_window_aspect_ratio = "16 9";
        };

        dwindle = {
          # pseudotile = true;
          preserve_split = true;
          force_split = 2;
        };

        decoration = lib.mkForce {
          rounding = 8;
          blur.enabled = true;
        };

        master = {
          allow_small_split = true;
          mfact = 0.32;
          new_on_top = false;
        };

        binds = {
          drag_threshold = 10;
          allow_workspace_cycles = true;
        };

        workspace =
          map (i: "${toString i}, persistent:true") persistentWorkspaces;
      };
    };
  };
}
