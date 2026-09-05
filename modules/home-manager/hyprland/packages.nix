{
  lib,
  config,
  pkgs,
  pkgs-stable,
  dotfilesPkgs,
  ...
}: {
  config = lib.mkIf config.dotfiles.hyprland.enable {
    programs.mpv.enable = true;

    home.packages = [
      dotfilesPkgs.ultrashell
      pkgs.pavucontrol
      pkgs.nautilus
      pkgs.libnotify
      pkgs.wtype
      pkgs.wl-clipboard

      # These track the compositor's IPC and protocol versions, so they come
      # from the release channel even though they live in the home layer.
      # See ADR-0007.
      pkgs-stable.quickshell
      pkgs-stable.hyprpaper
      pkgs-stable.hyprshot
      pkgs-stable.hyprpicker
      pkgs-stable.hyprcursor
    ];
  };
}
