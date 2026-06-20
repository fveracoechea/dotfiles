{
  lib,
  config,
  pkgs,
  ...
}: {
  options.dotfiles.volta.enable = lib.mkEnableOption "Volta JS toolchain manager";

  config = lib.mkIf config.dotfiles.volta.enable {
    home.packages = [
      pkgs.volta
    ];

    home.sessionVariables = {
      VOLTA_HOME = "${config.home.homeDirectory}/.volta";
    };

    home.sessionPath = [
      "$VOLTA_HOME/bin"
    ];
  };
}
