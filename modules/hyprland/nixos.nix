{
  lib,
  config,
  pkgs,
  ...
}:
{
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

    programs.dms-shell = {
      enable = true;
      package = pkgs.dms-shell;
      quickshell.package = pkgs.quickshell;
      systemd.enable = true;
      systemd.target = "wayland-session@hyprland.desktop.target";
      enableSystemMonitoring = true;
      enableVPN = false;
      enableDynamicTheming = false;
      enableAudioWavelength = false;
      enableCalendarEvents = false;
    };

    systemd.user.services.dms = {
      after = [ "wayland-session@hyprland.desktop.target" ];
      requisite = [ "wayland-session@hyprland.desktop.target" ];
      partOf = [ "wayland-session@hyprland.desktop.target" ];
      serviceConfig.Environment = [
        "DMS_DISABLE_MATUGEN=1"
        "QS_DISABLE_CRASH_HANDLER=1"
      ];
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
    };
  };
}
