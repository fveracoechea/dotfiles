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
              do = "enable-stream-output";
              undo = "disable-stream-output";
            }
          ];
        }
        {
          name = "Steam Big Picture";
          image-path = "steam.png";
          auto-detach = "true";
          prep-cmd = [
            {
              do = "enable-stream-output";
              undo = "disable-stream-output";
            }
          ];
        }
      ];
    };

    # Toggle the Dummy Plug output inside Hyprland (no-op elsewhere)
    home.packages = [
      (pkgs.writers.writeBashBin "enable-stream-output" ''
        hyprctl keyword monitor "HDMI-A-1, 3840x2160@120, 5120x0, 1" || true
      '')
      (pkgs.writers.writeBashBin "disable-stream-output" ''
        hyprctl keyword monitor "HDMI-A-1, disable" || true
      '')
    ];
  };
}
