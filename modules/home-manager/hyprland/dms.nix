{
  lib,
  config,
  pkgs,
  dmsThemeSource,
  ...
}: {
  config = lib.mkIf config.dotfiles.hyprland.enable {
    programs.dank-material-shell = let
      barLengthPadding = 1612; # DO NOT CHANGE
    in {
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
          accent = "blue";
        };

        runUserMatugenTemplates = false;
        widgetBackgroundColor = "s";
        cornerRadius = 12;
        clockFormat = "12h";
        useFahrenheit = true;
        m3ElevationEnabled = false;
        barElevationEnabled = false;
        blurBorderOpacity = 1;
        systemTrayIconTintMode = "secondary";
        controlCenterWidgets = [
          {
            id = "volumeSlider";
            enabled = true;
            width = 50;
          }
          {
            id = "brightnessSlider";
            enabled = true;
            width = 50;
          }
          {
            id = "wifi";
            enabled = true;
            width = 50;
          }
          {
            id = "bluetooth";
            enabled = true;
            width = 50;
          }
          {
            id = "audioOutput";
            enabled = true;
            width = 50;
          }
          {
            id = "audioInput";
            enabled = true;
            width = 50;
          }
          {
            id = "doNotDisturb";
            enabled = true;
            width = 50;
          }
          {
            id = "idleInhibitor";
            enabled = true;
            width = 50;
          }
          {
            id = "builtin_tailscale";
            enabled = true;
            width = 50;
          }
          {
            id = "colorPicker";
            enabled = true;
            width = 50;
          }
        ];
        useAutoLocation = true;
        fontScale = 1.1;
        textRenderType = 1;
        syncModeWithPortal = false;
        runDmsMatugenTemplates = false;
        lockScreenShowMediaPlayer = false;
        lockScreenShowWeather = false;
        lockScreenWallpaperPath = "${config.home.homeDirectory}/dotfiles/assets/wallpapers/dark-forrest-ultrawide.png";
        screenPreferences.wallpaper = [];

        barConfigs = [
          {
            attachToScreenEdge = true;
            autoHide = false;
            autoHideDelay = 250;
            autoHideStrict = false;
            barInsetPadding = 4;
            inherit barLengthPadding;
            batteryColorMode = "theme";
            borderColor = "surfaceText";
            borderEnabled = false;
            borderOpacity = 1;
            borderThickness = 1;
            bottomGap = 10;
            centerWidgets = [
              {
                id = "weather";
                enabled = true;
              }
              {
                id = "spacer";
                enabled = true;
                size = 10;
              }
              {
                id = "clock";
                enabled = true;
                clockCompactMode = false;
                clockDateOrder = "dateFirst";
              }
              {
                id = "spacer";
                enabled = true;
                size = 10;
              }
              {
                id = "controlCenterButton";
                enabled = true;
                showNetworkIcon = false;
                showVpnIcon = false;
                showBrightnessIcon = false;
                showBrightnessPercent = false;
                showIdleInhibitorIcon = true;
                showDoNotDisturbIcon = false;
                showScreenSharingIcon = true;
                showBluetoothIcon = true;
                showAudioPercent = false;
                showAudioIcon = true;
                showMicIcon = true;
                showMicPercent = false;
              }
            ];
            clickThrough = false;
            enabled = true;
            fontScale = 1.2;
            gothCornerRadiusOverride = false;
            gothCornerRadiusValue = 12;
            gothCornersEnabled = false;
            hoverPopoutDelay = 150;
            hoverPopouts = false;
            iconScale = 1.35;
            id = "default";
            innerPadding = 4;
            leftWidgets = [
              {
                id = "powerMenuButton";
                enabled = true;
              }
              {
                id = "workspaceSwitcher";
                enabled = true;
              }
              {
                id = "systemTray";
                enabled = true;
                trayIconSpacing = 2;
              }
              {
                id = "capsLockIndicator";
                enabled = true;
              }
            ];
            maximizeDetection = true;
            maximizeWidgetIcons = false;
            maximizeWidgetText = false;
            name = "Main Bar";
            noBackground = true;
            openOnOverview = false;
            popupGapsAuto = true;
            popupGapsManual = 13;
            position = 0;
            removeWidgetPadding = false;
            rightWidgets = [
              {
                id = "music";
                enabled = true;
                mediaSize = 0;
              }
              {
                id = "cpuUsage";
                enabled = true;
                minimumWidth = false;
              }
              {
                id = "cpuTemp";
                enabled = true;
                minimumWidth = false;
              }
              {
                id = "memUsage";
                enabled = true;
                minimumWidth = false;
                showInGb = false;
                showSwap = false;
              }
              {
                id = "notificationButton";
                enabled = true;
              }
            ];
            screenPreferences = ["all"];
            scrollEnabled = true;
            scrollXBehavior = "column";
            scrollYBehavior = "workspace";
            shadowColorMode = "default";
            shadowCustomColor = "#000000";
            shadowDirection = "top";
            shadowDirectionMode = "inherit";
            shadowIntensity = 0;
            shadowOpacity = 60;
            showOnLastDisplay = true;
            showOnWindowsOpen = false;
            spacing = 0;
            squareCorners = false;
            transparency = 1;
            useOverlayLayer = false;
            visible = true;
            widgetOutlineColor = "surfaceText";
            widgetOutlineEnabled = false;
            widgetOutlineOpacity = 1;
            widgetOutlineThickness = 1;
            widgetPadding = 8;
            widgetTransparency = 1;
          }
        ];

        desktopClockCustomColor = {
          r = 1;
          g = 1;
          b = 1;
          a = 1;
          hsvHue = -1;
          hsvSaturation = 0;
          hsvValue = 1;
          hslHue = -1;
          hslSaturation = 0;
          hslLightness = 1;
          valid = true;
        };
        systemMonitorCustomColor = {
          r = 1;
          g = 1;
          b = 1;
          a = 1;
          hsvHue = -1;
          hsvSaturation = 0;
          hsvValue = 1;
          hslHue = -1;
          hslSaturation = 0;
          hslLightness = 1;
          valid = true;
        };
        builtInPluginSettings = {
          dms_settings_search.trigger = "?";
          dms_clipboard_search.trigger = "cb";
          dms_power.trigger = "pw";
          dms_qr_generator.trigger = "qrg";
        };
        clipboardEnterToPaste = true;
        frameThickness = 8;
        frameRounding = 8;
        frameBarSize = 45;
        frameCloseGaps = false;
        frameLauncherArcExtender = true;
        barInsetPaddingShared = 8;
        barInsetPaddingSyncAll = true;
        configVersion = 18;
      };

      session = {
        recentColors = ["#00634f97"];
        lastPlayerIdentity = "Chrome";
        lastAppliedIconTheme = "Papirus-Dark";
        launcherQueryHistory = ["set"];
        settingsSidebarExpandedIds = ",dock_launcher,applications,system,power_security,";
        settingsSidebarCollapsedIds = ",network,";
        configVersion = 4;
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
