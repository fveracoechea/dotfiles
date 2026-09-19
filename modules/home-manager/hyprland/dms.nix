{
  lib,
  config,
  pkgs,
  dmsThemeSource,
  ...
}: {
  config = lib.mkIf config.dotfiles.hyprland.enable {
    programs.dank-material-shell = {
      enable = true;
      systemd.enable = true;

      enableSystemMonitoring = true;
      enableVPN = false;
      enableDynamicTheming = false;
      enableAudioWavelength = false;
      enableCalendarEvents = false;

      # DMS owns this package and requires its current QML APIs, so it follows
      # the Home layer's Latest Channel instead of Hyprland's Release Channel.
      quickshell.package = pkgs.quickshell;

      settings = {
        currentThemeName = "custom";
        currentThemeCategory = "custom";
        customThemeFile = "${dmsThemeSource}/catppuccin.json";
        registryThemeVariants.catppuccin.dark = {
          flavor = "mocha";
          accent = "mauve";
        };

        runDmsMatugenTemplates = false;
        runUserMatugenTemplates = false;

        appLauncherViewMode = "list";
        spotlightModalViewMode = "list";
        launcherUseOverlayLayer = false;
        workspaceFollowFocus = false;
        screenPreferences.wallpaper = [];

        frameEnabled = true;
        frameMode = "connected";

        clipboardEnterToPaste = true;
        clipboardUseOverlayLayer = false;

        notificationOverlayEnabled = false;
        notificationDndAllowCritical = true;

        lockScreenShowMediaPlayer = false;
        lockScreenShowWeather = false;
        lockScreenWallpaperPath = "${config.home.homeDirectory}/dotfiles/assets/wallpapers/dark-forrest-ultrawide.png";
      };

      clipboardSettings = {
        maxHistory = 25;
        maxEntrySize = 5242880;
        autoClearDays = 1;
        clearAtStartup = true;
        disabled = false;
        maxPinned = 5;
      };
    };

    systemd.user.services.dms.Service.Environment = ["DMS_DISABLE_MATUGEN=1"];
  };
}
