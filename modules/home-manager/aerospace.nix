{
  lib,
  config,
  pkgs,
  ...
}: {
  options.dotfiles.aerospace.enable = lib.mkEnableOption "Aerospace macOS tiling window manager";

  config = lib.mkIf (config.dotfiles.aerospace.enable && pkgs.stdenv.isDarwin) {
    xdg.enable = true;

    programs.aerospace = {
      enable = true;

      launchd.enable = true;

      settings = {
        gaps = {
          inner.horizontal = 8;
          inner.vertical = 8;
          outer.left = 8;
          outer.right = 8;
          outer.top = 8;
          outer.bottom = 8;
        };

        mode.main.binding = {
          # Focus
          alt-h = "focus left";
          alt-j = "focus down";
          alt-k = "focus up";
          alt-l = "focus right";

          # Move
          alt-shift-h = "move left";
          alt-shift-j = "move down";
          alt-shift-k = "move up";
          alt-shift-l = "move right";

          # Workspaces
          alt-1 = "workspace 1";
          alt-2 = "workspace 2";
          alt-3 = "workspace 3";
          alt-4 = "workspace 4";
          alt-5 = "workspace 5";
          alt-6 = "workspace 6";
          alt-7 = "workspace 7";
          alt-8 = "workspace 8";
          alt-9 = "workspace 9";

          # Move to workspace
          alt-shift-1 = "move-node-to-workspace 1";
          alt-shift-2 = "move-node-to-workspace 2";
          alt-shift-3 = "move-node-to-workspace 3";
          alt-shift-4 = "move-node-to-workspace 4";
          alt-shift-5 = "move-node-to-workspace 5";
          alt-shift-6 = "move-node-to-workspace 6";
          alt-shift-7 = "move-node-to-workspace 7";
          alt-shift-8 = "move-node-to-workspace 8";
          alt-shift-9 = "move-node-to-workspace 9";

          # Layouts
          alt-slash = "layout tiles horizontal vertical";
          alt-comma = "layout accordion horizontal vertical";
          alt-f = "layout floating tiling";

          # Resize
          alt-shift-minus = "resize smart -50";
          alt-shift-equal = "resize smart +50";

          # Reload config
          alt-shift-r = "reload-config";
        };

        on-window-detected = [
          {
            "if".app-id = "com.apple.systempreferences";
            run = "layout floating";
          }
          {
            "if".app-id = "com.apple.finder";
            run = "layout floating";
          }
          {
            "if".app-id = "com.1password.1password";
            run = "layout floating";
          }
          {
            "if".app-id = "com.apple.ActivityMonitor";
            run = "layout floating";
          }
        ];
      };
    };
  };
}
