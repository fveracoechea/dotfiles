{
  lib,
  config,
  ...
}: {
  options.dotfiles.handy.enable = lib.mkEnableOption "Handy virtual input access";

  config = lib.mkIf config.dotfiles.handy.enable {
    hardware.uinput.enable = true;
  };
}
