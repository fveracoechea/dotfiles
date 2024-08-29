{pkgs, ...}: {
  gtk.enable = true;


  home.packages = with pkgs; [
    gnomeExtensions.freon
    gnomeExtensions.dash2dock-lite
    gnomeExtensions.blur-my-shell
    gnomeExtensions.system-monitor
  ];

  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;

      # `gnome-extensions list` for a list
      enabled-extensions = [
        "blur-my-shell@aunetx"
        "dash2dock-lite@icedman.github.com"
      ];
    };

    "org/gnome/shell/extensions/dash2dock-lite" = {
      animation-bounce = 0.75;
      animation-magnify = 0.17000000000000001;
      animation-rise = 0.25;
      animation-spread = 0.34999999999999998;
      apps-icon = true;
      apps-icon-front = false;
      autohide-dash = false;
      autohide-speed = 0.5;
      blur-resolution = 0;
      border-radius = 1.3678756476683938;
      dock-location = 1;
      dock-padding = 0.43478260869565216;
      edge-distance = 0.49425287356321834;
      favorites-only = false;
      icon-effect = 0;
      icon-size = 0.13846153846153847;
      icon-spacing = 0.54273504273504269;
      items-pullout-angle = 0.5;
      msg-to-ext = "";
      open-app-animation = true;
      panel-mode = false;
      preferred-monitor = 0;
      pressure-sense = false;
      pressure-sense-sensitivity = 0.40000000000000002;
      scroll-sensitivity = 0.40000000000000002;
      shrink-icons = true;
      trash-icon = false;
    };

    "or/gnome/shell/extensions/freon" = {
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

    "gnome/shell/extensions/system-monitor" = {
      show-cpu = true;
      show-download = false;
      show-memory = true;
      show-swap = true;
      show-upload = false;
    };
  };

}
