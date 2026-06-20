{
  pkgs,
  lib,
  config,
  ...
}: {
  options.dotfiles.display-manager.enable = lib.mkEnableOption "display manager (Ly)";

  config = lib.mkIf config.dotfiles.display-manager.enable {
    environment.systemPackages = with pkgs; [
      cmatrix
      terminus_font
    ];

    console = let
      p = config.dotfiles.palette;
    in {
      earlySetup = true;
      font = "${pkgs.terminus_font}/share/consolefonts/ter-u24n.psf.gz";
      packages = with pkgs; [terminus_font];
      keyMap = "us";
      colors = map (color: (lib.substring 1 6 (lib.strings.toLower color))) [
        p.base
        p.red
        p.green
        p.yellow
        p.blue
        p.pink
        p.teal
        p.subtext1

        p.surface2
        p.red
        p.green
        p.yellow
        p.blue
        p.pink
        p.teal
        p.subtext0
      ];
    };

    services.displayManager = {
      ly.enable = true;
      ly.settings = {
        animate = true;
        animation = "matrix";
      };
    };
  };
}
