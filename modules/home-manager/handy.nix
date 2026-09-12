{
  lib,
  config,
  pkgs,
  ...
}: {
  options.dotfiles.handy.enable = lib.mkEnableOption "Handy speech-to-text application";

  config = lib.mkIf config.dotfiles.handy.enable {
    home.packages = [pkgs.handy];
  };
}
