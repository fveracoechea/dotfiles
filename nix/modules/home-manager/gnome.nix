{pkgs, ...}: {
  gtk.enable = true;

  home.packages = with pkgs; [
    kooah
    slack
    google-chrome
    gnomeExtensions.freon
    gnomeExtensions.dash2dock-lite
    gnomeExtensions.blur-my-shell
    gnomeExtensions.system-monitor
    gnomeExtensions.workspace-indicator
    gnomeExtensions.auto-move-windows
  ];

  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      search-filter-time-type = "last_modified";
      default-folder-viewer = "list-view";
      default-sort-order = "mtime";
    };

    "org/gnome/shell" = {
      disable-user-extensions = false;
      always-show-log-out = true;
      enabled-extensions = [
        "blur-my-shell@aunetx"
        "dash2dock-lite@icedman.github.com"
        "freon@UshakovVasilii_Github.yahoo.com"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
      ];
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "google-chrome.desktop"
        "org.gnome.Settings.desktop"
        "kitty.desktop"
        "slack.desktop"
        "io.github.seadve.Kooha.desktop"
      ];
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

    "org/gnome/shell/extensions/dash2dock-lite" = {
      animation-rise = 0.44;
      animation-spread = 0.10000000000000001;
      apps-icon-front = false;
      background-color = "(0.0, 0.0, 0.0, 0.37000000476837158)";
      blur-background = true;
      blur-resolution = 0;
      calendar-icon = false;
      customize-label = false;
      dock-location = 1;
      dock-padding = 0.86521739130434783;
      downloads-icon = false;
      edge-distance = 0.47126436781609193;
      icon-resolution = 0;
      icon-shadow = true;
      icon-size = 0.085897435897435898;
      icon-spacing = 0.44444444444444442;
      label-border-radius = 0.0;
      mounted-icon = false;
      panel-mode = false;
      pressure-sense = false;
      running-indicator-size = 2;
      running-indicator-style = 1;
      shrink-icons = false;
      trash-icon = true;
    };
  };
}
