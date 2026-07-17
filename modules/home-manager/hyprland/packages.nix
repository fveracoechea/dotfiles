{
  lib,
  config,
  pkgs,
  dotfilesPkgs,
  ...
}: {
  config = lib.mkIf config.dotfiles.hyprland.enable {
    programs.mpv.enable = true;

    home.packages = with pkgs; [
      dotfilesPkgs.ultrashell
      hyprpaper
      hyprshot
      hyprpicker
      hyprcursor
    ];
  };
}
