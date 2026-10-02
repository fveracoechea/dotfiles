{
  pkgs,
  lib,
  config,
  ...
}: {
  options.dotfiles.sunshine.enable = lib.mkEnableOption "Sunshine game streaming config";

  config = lib.mkIf config.dotfiles.sunshine.enable {
    # NOTE: managed declaratively, so the web UI can't persist changes to this file
    # No output_name: name-based selection resolves via Wayland monitor
    # correlation is not reliable in the plain Steam Session.
    # Empty selects the first active KMS plane, the Dummy Plug in either session.
    xdg.configFile."sunshine/sunshine.conf".text = ''
      vaapi_strict_rc_buffer = enabled
      encoder = vaapi
      capture = kms
      system_tray = disabled
    '';

    xdg.configFile."sunshine/apps.json".text = builtins.toJSON {
      env = {
        "PATH" = "$(PATH):$(HOME)/.local/bin";
      };
      apps = [
        {
          name = "Desktop";
          image-path = "desktop.png";
          prep-cmd = [
            {
              do = "prepare-steam-stream";
            }
          ];
        }
        {
          name = "Steam Big Picture";
          image-path = "steam.png";
          auto-detach = "true";
          prep-cmd = [
            {
              do = "prepare-steam-stream";
            }
          ];
        }
      ];
    };

    home.packages = [
      (pkgs.writers.writeBashBin "prepare-steam-stream" ''
        set -euo pipefail

        display="''${DISPLAY:-:0}"
        ${pkgs.xprop}/bin/xprop -display "$display" -root GAMESCOPE_COMPOSITE_FORCE

        # Steam can override --force-composition after Gamescope starts.
        ${pkgs.xprop}/bin/xprop -display "$display" -root -f GAMESCOPE_COMPOSITE_FORCE 32c -set GAMESCOPE_COMPOSITE_FORCE 1
        ${pkgs.coreutils}/bin/sleep 0.5

        composition=$(${pkgs.xprop}/bin/xprop -display "$display" -root GAMESCOPE_COMPOSITE_FORCE)
        printf '%s\n' "$composition"
        if [[ "$composition" != "GAMESCOPE_COMPOSITE_FORCE(CARDINAL) = 1" ]]; then
          printf 'Gamescope did not retain forced composition\n' >&2
          exit 1
        fi
      '')
    ];
  };
}
