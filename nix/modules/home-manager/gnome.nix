{pkgs, ...}: {
  gtk.enable = true;

  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;

      # `gnome-extensions list` for a list
      enabled-extensions = [
        "blur-my-shell@aunetx"
        "dash2dock-lite@icedman.github.com"
        "Vitals@CoreCoding.com"
        "sound-output-device-chooser@kgshank.net"
      ];
    };
  };

  home.packages = with pkgs; [
    gnomeExtensions.vitals
    gnomeExtensions.dash2dock-lite
    gnomeExtensions.sound-output-device-chooser
    gnomeExtensions.blur-my-shell
  ];
}
