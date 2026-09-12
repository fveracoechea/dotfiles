{
  lib,
  config,
  pkgs-stable,
  ...
}: {
  config = lib.mkIf config.dotfiles.hyprland.enable {
    services.hypridle = {
      enable = true;
      # Release Channel: tracks the compositor. See ADR-0007.
      package = pkgs-stable.hypridle;

      settings = {
        general = {
          ignore_dbus_inhibit = false;
          lock_cmd = "hyprlock";
        };

        listener = [
          {
            # lock screen after 15mins
            timeout = 900;
            on-timeout = "hyprlock";
          }
          {
            # suspend after 30mins
            timeout = 1800;
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  };
}
