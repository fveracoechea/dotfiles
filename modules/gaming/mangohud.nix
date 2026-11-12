{
  lib,
  config,
  ...
}: {
  options.dotfiles.mangohud.enable = lib.mkEnableOption "MangoHud performance overlay";

  config = lib.mkIf config.dotfiles.mangohud.enable {
    programs.mangohud = {
      enable = true;
      settings = {
        position = "bottom-left";
        horizontal = true;
        hud_compact = true;
        hud_no_margin = true;
      };
    };
  };
}
