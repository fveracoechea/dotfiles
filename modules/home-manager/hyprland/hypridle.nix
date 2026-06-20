{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.dotfiles.hyprland.enable {
    services.hypridle = {
      enable = true;

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
