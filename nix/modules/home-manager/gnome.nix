{pkgs, ...}: {
  gtk.enable = true;

  home.packages = with pkgs; [
    gnomeExtensions.freon
    gnomeExtensions.dash2dock-lite
    gnomeExtensions.blur-my-shell
    gnomeExtensions.system-monitor
    gnomeExtensions.workspace-indicator
    gnomeExtensions.auto-move-windows
  ];

  dconf.settings = {
    "org/gnome" = {
      "nautilus/preferences" = {
        search-filter-time-type = "last_modified";
        default-folder-viewer = "list-view";
        default-sort-order = "mtime";
      };
      "shell" = {
        disable-user-extensions = false;
        always-show-log-out = true;
        # `gnome-extensions list` for a list
        enabled-extensions = [
          "blur-my-shell@aunetx"
          "dash2dock-lite@icedman.github.com"
          "freon@UshakovVasilii_Github.yahoo.com"
          "system-monitor@gnome-shell-extensions.gcampax.github.com"
          "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
          "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
        ];
        "extensions" = {
          "freon" = {
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
          "system-monitor" = {
            show-cpu = true;
            show-download = false;
            show-memory = true;
            show-swap = true;
            show-upload = false;
          };
          "dash2dock-lite" = {
          };
        };
      };
    };
  };
}
