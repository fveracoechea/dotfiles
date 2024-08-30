{lib, ...}: {
  # Generated with dconf2nix
  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      search-filter-time-type = "last_modified";
      default-folder-viewer = "list-view";
      default-sort-order = "mtime";
    };
    "org/gnome/shell" = {
      always-show-log-out = true;
      disable-user-extensions = false;
      enabled-extensions = [
        "blur-my-shell@aunetx"
        "dash2dock-lite@icedman.github.com"
        "freon@UshakovVasilii_Github.yahoo.com"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
      ];
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "google-chrome.desktop"
        "org.gnome.Settings.desktop"
        "kitty.desktop"
        "slack.desktop"
        "io.github.seadve.Kooha.desktop"
      ];
      disabled-extensions = [
        "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
        "screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        "native-window-placement@gnome-shell-extensions.gcampax.github.com"
        "apps-menu@gnome-shell-extensions.gcampax.github.com"
        "light-style@gnome-shell-extensions.gcampax.github.com"
      ];
      last-selected-power-profile = "power-saver";
      welcome-dialog-last-shown-version = "46.2";
    };

    "org/gnome/shell/extensions/blur-my-shell" = {
      settings-version = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
      blur = true;
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur = true;
      pipeline = "pipeline_default_rounded";
    };

    "org/gnome/shell/extensions/blur-my-shell/hidetopbar" = {
      compatibility = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/lockscreen" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/overview" = {
      blur = true;
      pipeline = "pipeline_default";
      style-components = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      blur = true;
      force-light-text = true;
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/screenshot" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/dash2dock-lite" = {
      animation-bounce = 0.75;
      animation-magnify = 0.3;
      animation-rise = 0.44;
      animation-spread = 0.25;
      apps-icon-front = false;
      autohide-dash = false;
      autohide-speed = 0.5;
      background-color = lib.hm.gvariant.mkTuple [
        0.11764705926179886
        0.11764705926179886
        0.18039216101169586
        0.75
      ];
      blur-background = true;
      blur-resolution = 0;
      border-radius = 3.0;
      border-thickness = 0;
      calendar-icon = false;
      customize-label = true;
      customize-topbar = false;
      dock-location = 1;
      dock-padding = 0.85;
      downloads-icon = false;
      edge-distance = 0.48;
      icon-resolution = 0;
      icon-shadow = true;
      icon-size = 8.5e-2;
      icon-spacing = 0.45;
      label-background-color = lib.hm.gvariant.mkTuple [
        0.11764705926179886
        0.11764705926179886
        0.18039216101169586
        0.75
      ];
      label-border-radius = 2.25;
      label-foreground-color = lib.hm.gvariant.mkTuple [
        0.8039215803146362
        0.8392156958580017
        0.95686274766922
        1.0
      ];
      mounted-icon = false;
      msg-to-ext = "";
      open-app-animation = true;
      panel-mode = false;
      preferred-monitor = 0;
      pressure-sense = false;
      pressure-sense-sensitivity = 0.4;
      running-indicator-size = 2;
      running-indicator-style = 1;
      scroll-sensitivity = 0.4;
      shrink-icons = false;
      topbar-border-thickness = 0;
      trash-icon = true;
    };
    "org/gnome/shell/extensions/freon" = {
      exec-method-freeipmi = "pkexec";
      hot-sensors = ["__average__" "__max__"];
      panel-box-index = 0;
      show-voltage = true;
      unit = "centigrade";
      update-time = 8;
      use-gpu-aticonfig = false;
      use-gpu-bumblebeenvidia = true;
      use-gpu-nvidia = false;
    };
    "org/gnome/shell/extensions/system-monitor" = {
      show-cpu = true;
      show-download = false;
      show-memory = true;
      show-swap = true;
      show-upload = false;
    };
    "org/gnome/shell/extensions/user-theme" = lib.mkForce {
      name = "Colloid-Dark-Catppuccin";
    };
    "world-clocks" = {
      locations = [];
    };
  };
}
