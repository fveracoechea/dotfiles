{
  lib,
  config,
  pkgs,
  pkgs-stable,
  ...
}: let
  luaFiles = {
    settings = {
      content = pkgs.replaceVars ./assets/settings.lua {
        catppuccinMocha = "${pkgs.catppuccin-hyprland}/share/themes/catppuccin-hyprland-themes/catppuccin-mocha.lua";
      };
      autoLoad = false;
    };
    bindings = {
      content = ./assets/bindings.lua;
      autoLoad = false;
    };
    windowrule = {
      content = ./assets/windowrule.lua;
      autoLoad = false;
    };
  };
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
      systemd.enable = false;
      package = null;
      portalPackage = null;
      configType = "lua";
      settings = {};
      extraConfig = builtins.readFile ./assets/entry.lua;
      extraLuaFiles = luaFiles;
    };

    # Home Manager skips its own config reload when package = null.
    xdg.configFile."dotfiles/hyprland.stamp" = {
      text = builtins.hashString "sha256" (builtins.toJSON {
        entry = builtins.hashFile "sha256" ./assets/entry.lua;
        modules = lib.mapAttrs (_: file: builtins.hashFile "sha256" file.content) luaFiles;
      });
      onChange = reload;
    };
  };
}
