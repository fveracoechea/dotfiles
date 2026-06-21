{
  lib,
  config,
  ...
}: {
  options.dotfiles.system-defaults.enable = lib.mkEnableOption "macOS system defaults";

  config = lib.mkIf config.dotfiles.system-defaults.enable {
    system.defaults = {
      finder = {
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
        ShowExternalHardDrivesOnDesktop = true;
      };

      dock = {
        autohide = false;
        autohide-delay = 0.0;
        mru-spaces = false;
        show-recents = false;
        largesize = 60;
        tilesize = 40;
        magnification = true;
        mineffect = "genie";
        orientation = "left";
      };
    };
  };
}
