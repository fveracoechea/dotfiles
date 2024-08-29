{pkgs, ...}: {
  gtk.enable = true;

  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;

      # `gnome-extensions list` for a list
      enabled-extensions = [
        "blur-my-shell@aunetx"
        "dash2dock-lite@icedman.github.com"
      ];
    };
  };

  home.packages = with pkgs; [
    gnomeExtensions.vitals
    gnomeExtensions.dash2dock-lite
    gnomeExtensions.blur-my-shell
  ];
}
