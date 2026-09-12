{
  lib,
  config,
  ...
}: {
  options.dotfiles.bootloader.enable = lib.mkEnableOption "bootloader (GRUB)";

  config = lib.mkIf config.dotfiles.bootloader.enable {
    boot.loader = {
      timeout = 3;
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        configurationLimit = 5;
      };
    };
  };
}
