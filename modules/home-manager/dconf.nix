{lib, ...}:
with lib.hm.gvariant; {
  # Generated with dconf2nix
  dconf.settings = {
    "org/gnome/mutter" = {
      experimental-features = ["variable-refresh-rate"];
    };

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
        "dash-to-dock@micxgx.gmail.com"
        "tilingshell@ferrarodomenico.com"
        "freon@UshakovVasilii_Github.yahoo.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
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
        "native-window-placement@gnome-shell-extensions.gcampax.github.com"
        "apps-menu@gnome-shell-extensions.gcampax.github.com"
        "light-style@gnome-shell-extensions.gcampax.github.com"
      ];
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
      override-background = true;
      static-blur = true;
      style-dash-to-dock = 0;
      unblur-in-overview = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/hidetopbar" = {
      compatibility = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/lockscreen" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/overview" = {
      blur = true;
      pipeline = "prpeline_default";
      style-components = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      blur = true;
      force-light-text = true;
      pipeline = "pipeline_default";
      override-background = true;
      override-background-dynamically = false;
      static-blur = true;
      style-panel = 0;
      unblur-in-overview = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/screenshot" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      always-center-icons = false;
      animation-time = 0.20000000000000001;
      apply-custom-theme = true;
      autohide = true;
      autohide-in-fullscreen = false;
      background-opacity = 0.80000000000000004;
      custom-background-color = false;
      custom-theme-shrink = true;
      dash-max-icon-size = 46;
      disable-overview-on-startup = false;
      dock-fixed = false;
      dock-position = "LEFT";
      extend-height = false;
      height-fraction = 1.0;
      hide-delay = 0.20000000000000001;
      intellihide = true;
      intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
      preferred-monitor = -2;
      preferred-monitor-by-connector = "Virtual-1";
      pressure-threshold = 100.0;
      preview-size-scale = 0.80000000000000004;
      require-pressure-to-show = true;
      running-indicator-style = "DOTS";
      scroll-action = "do-nothing";
      show-delay = 0.25;
      show-dock-urgent-notify = true;
      show-favorites = true;
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

    "world-clocks" = {
      locations = [];
    };

    "org/gnome/shell/extensions/tilingshell" = {
      enable-blur-selected-tilepreview = true;
      enable-blur-snap-assistant = true;
      inner-gaps = 16;
      last-version-name-installed = "11.1";
      outer-gaps = mkUint32 16;
      show-indicator = true;
    };
  };
}
