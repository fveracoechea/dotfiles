{
  lib,
  config,
  ...
}: {
  options.dotfiles.lazydocker.enable = lib.mkEnableOption "lazydocker (terminal UI for docker)";

  config = lib.mkIf config.dotfiles.lazydocker.enable {
    programs.lazydocker.enable = true;
  };
}
