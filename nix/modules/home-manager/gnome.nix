{
  pkgs,
  unstable,
  lib,
  ...
}: {
  gtk = {
    enable = true;
    theme = lib.mkForce {
      name = "Colloid-Dark-Catppuccin";
      package = unstable.colloid-gtk-theme.override {
        tweaks = ["catppuccin"];
      };
    };
    iconTheme = lib.mkForce {
      name = "Colloid-dark";
      package = unstable.colloid-icon-theme;
    };
  };

  home.packages = with pkgs; [
    ripgrep
    eza
    yazi
    btop
    lazygit
    oh-my-posh
    volta
    fira-code-nerdfont
    neofetch
    python3
    cmatrix
    nurl
    kooha
    slack
    google-chrome
    dconf2nix
    # unstable packages
    unstable.deno
    unstable.neovim
    # gnome extensions
    gnome.gnome-tweaks
    gnome.dconf-editor
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
    };

    "org/gnome/shell/extensions/user-theme" = lib.mkForce {
      name = "Colloid-Dark-Catppuccin";
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
      animation-spread = 0.25;
      apps-icon-front = false;
      background-color = "(30, 30, 46, 0.60)";
      blur-background = true;
      blur-resolution = 0;
      calendar-icon = false;
      customize-label = false;
      dock-location = 1;
      dock-padding = 0.85;
      downloads-icon = false;
      edge-distance = 0.48;
      icon-resolution = 0;
      icon-shadow = true;
      icon-size = 0.085;
      icon-spacing = 0.45;
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
