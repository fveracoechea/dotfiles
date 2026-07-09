{
  lib,
  config,
  ...
}: {
  options.dotfiles.darwin-system-config.enable = lib.mkEnableOption "macOS system defaults";

  config = lib.mkIf config.dotfiles.darwin-system-config.enable {
    system.defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        KeyRepeat = 4; # fast key repeat
        InitialKeyRepeat = 15; # short delay before repeat
        _HIHideMenuBar = false; # auto-hide the menu bar
        AppleShowAllExtensions = true;
      };

      finder = {
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
        ShowExternalHardDrivesOnDesktop = true;
        FXPreferredViewStyle = "Nlsv"; # list view by default
        CreateDesktop = false; # clean desktop
      };

      trackpad.Clicking = true;

      dock = {
        autohide = true;
        autohide-delay = 0.0;
        mru-spaces = false;
        show-recents = false;
        largesize = 65;
        tilesize = 50;
        magnification = true;
        mineffect = "genie";
        orientation = "bottom";
      };
    };
  };
}
