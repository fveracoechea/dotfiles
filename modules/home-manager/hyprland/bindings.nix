{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.dotfiles.hyprland.enable {
    wayland.windowManager.hyprland.settings = {
      # Mouse bindings
      bindm = [
        "SHIFT_ALT, mouse:272, movewindow"
        # "ALT, mouse:273, resizewindow"
      ];

      # Bindings with descriptions
      # Inspired by Omarchy settings:
      # https://github.com/basecamp/omarchy/blob/7f9ee95e1ae5d327d8cb2cb5b58415f58147e535/default/hypr/bindings/tiling-v2.conf
      bindd = let
        terminal = "ghostty";
        workspaces = [1 2 3 4 5 6 7 8 9];
        browser = "google-chrome-stable";
        search = "fuzzel --cache ${config.home.homeDirectory}/.config/fuzzel/cache";

        openapp = key: app: "SUPER, ${key}, Open ${app}, exec, ${app}";
        movefocus = key: direction: "SUPER, ${key}, Move window focus ${lib.toUpper direction}, movefocus, ${direction}";
        resizeactive = key: delta: "SUPER CTRL, ${key}, Resize active window ${lib.toUpper key}, resizeactive, ${delta}";
      in
        [
          # CONTROL TILING
          "SUPER, J, Toggle window split, layoutmsg, togglesplit,"
          "SUPER, T, Toggle window floating/tiling, togglefloating,"
          "SUPER, F, Full screen, fullscreen, 0"
          "SUPER CTRL, F, Tiled full screen, fullscreenstate, 0 2"
          "SUPER ALT, F, Full width, fullscreen, 1"
          "SUPER, W, Close window, killactive"
          (movefocus "K" "u")
          (movefocus "J" "d")
          (movefocus "L" "r")
          (movefocus "H" "l")
          (resizeactive "K" "0 -100")
          (resizeactive "J" "0 100")
          (resizeactive "L" "100 0")
          (resizeactive "H" "-100 0")

          # DWINDLE SPECIFIC
          "SUPER, P, Pseudo window, pseudo,"
          "SUPER CTRL, P, Toggle All Pseudo window, exec, hyprctl dispatch workspaceopt allpseudo"

          # TAB BETWEEN WORKSPACES
          "SUPER, TAB, Next workspace, workspace, e+1"
          "SUPER SHIFT, TAB, Previous workspace, workspace, e-1"
          "SUPER CTRL, TAB, Former workspace, workspace, previous"

          # TOGGLE GROUPS
          "SUPER, G, Toggle window grouping, togglegroup"
          "SUPER ALT, G, Move active window out of group, moveoutofgroup"

          # APPLICATION SHORTCUTS
          (openapp "B" browser)
          (openapp "S" terminal)
          (openapp "A" search)
        ]
        # Switch workspaces with SUPER + [1-9]
        ++ (map (i: "SUPER, ${toString i}, Switch to workspace ${toString i}, workspace, ${toString i}") workspaces)
        # Move active window to a workspace with SUPER + SHIFT + [1-9]
        ++ (map (i: "SUPER SHIFT, ${toString i}, Move active window to workspace ${toString i}, movetoworkspace, ${toString i}") workspaces);
    };
  };
}
