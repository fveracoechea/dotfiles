{
  lib,
  config,
  pkgs,
  ...
}: {
  options.dotfiles.hyprland.enable = lib.mkEnableOption "Hyprland compositor";

  config = lib.mkIf config.dotfiles.hyprland.enable {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;

    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;

    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
    };
  };
}
