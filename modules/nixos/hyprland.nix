{
  lib,
  config,
  dotfilesPkgs,
  pkgs,
  ...
}: {
  options.dotfiles.hyprland.enable = lib.mkEnableOption "Hyprland compositor";

  config = lib.mkIf config.dotfiles.hyprland.enable {
    nix.settings = {
      substituters = ["https://hyprland.cachix.org"];
      trusted-substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };

    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;

    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;

    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
      package = dotfilesPkgs.hyprland;
      portalPackage = dotfilesPkgs.hyprland-portal;
    };

    environment.systemPackages = with pkgs; [
      wl-clipboard
      libnotify
      pavucontrol
      nautilus
    ];

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
    };
  };
}
