{
  lib,
  config,
  ...
}: {
  options.dotfiles.darwin-system-config.enable = lib.mkEnableOption "macOS system defaults";

  config = lib.mkIf config.dotfiles.darwin-system-config.enable {
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
