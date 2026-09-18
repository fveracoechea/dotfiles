{
  lib,
  config,
  pkgs,
  pkgs-stable,
  ...
}: let
  luaFiles = {
    entry = {
      content = ../../../config/hypr/entry.lua;
      autoLoad = true;
    };
    lifecycle = {
      content = ../../../config/hypr/lifecycle.lua;
      autoLoad = false;
    };
    bridge = {
      content = ../../../config/hypr/bridge.lua;
      autoLoad = false;
    };
    "lib.json" = {
      content = ../../../config/hypr/lib/json.lua;
      autoLoad = false;
    };
    "modules.settings" = {
      content = ../../../config/hypr/modules/settings.lua;
      autoLoad = false;
    };
    "modules.env" = {
      content = ../../../config/hypr/modules/env.lua;
      autoLoad = false;
    };
    "modules.bindings" = {
      content = ../../../config/hypr/modules/bindings.lua;
      autoLoad = false;
    };
    "modules.windowrules" = {
      content = ../../../config/hypr/modules/windowrules.lua;
      autoLoad = false;
    };
    "modules.theme" = {
      content = ../../../config/hypr/modules/theme.lua;
      autoLoad = false;
    };
  };
  # Version-Coupled client: reload the System-owned compositor from its channel.
  reload = ''
    (
      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
      if instances=$(${pkgs-stable.hyprland}/bin/hyprctl -j instances); then
        if signatures=$(printf '%s' "$instances" | ${pkgs.jq}/bin/jq -r '.[].instance'); then
          while IFS= read -r instance; do
            [ -n "$instance" ] || continue
            if ! ${pkgs-stable.hyprland}/bin/hyprctl -i "$instance" reload; then
              printf 'Hyprland reload failed for %s\n' "$instance" >&2
            fi
          done <<< "$signatures"
        else
          printf 'Cannot read Hyprland instance signatures\n' >&2
        fi
      else
        printf 'Cannot enumerate Hyprland instances\n' >&2
      fi
    )
  '';
in {
  config = lib.mkIf config.dotfiles.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;
      package = null;
      portalPackage = null;
      configType = "lua";
      settings = {};
      # Register user startup after Home Manager's systemd start hook.
      extraConfig = ''require("lifecycle")'';
      extraLuaFiles = luaFiles;
    };

    xdg.configFile = {
      "dotfiles/hyprland.json" = {
        text = builtins.toJSON {
          monitors = config.dotfiles.hyprland.monitors;
          theme = {inherit (config.dotfiles.palette) blue flamingo surface2;};
          paths.fuzzelCache = "${config.home.homeDirectory}/.config/fuzzel/cache";
        };
        onChange = reload;
      };
      # With package = null, upstream does not reload changed Lua sources.
      "dotfiles/hyprland.stamp" = {
        text = builtins.hashString "sha256" (builtins.toJSON (
          lib.mapAttrs (_: file: builtins.hashFile "sha256" file.content) luaFiles
        ));
        onChange = reload;
      };
    };
  };
}
