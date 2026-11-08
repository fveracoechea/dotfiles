{
  lib,
  config,
  dotfilesPkgs,
  ...
}: {
  options.dotfiles.hex.enable = lib.mkEnableOption "Hex voice dictation";

  config = lib.mkIf config.dotfiles.hex.enable {
    programs.hex = {
      enable = true;
      package = dotfilesPkgs.hex;
      autostart = true;
    };
  };
}
