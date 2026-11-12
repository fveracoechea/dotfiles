{
  lib,
  config,
  ...
}:
{
  imports = [
    ./settings.nix
    ./packages.nix
    ./hypridle.nix
    ./hyprpaper.nix
    ./hyprcursor.nix
    ./dms.nix
  ];

  options.dotfiles.hyprland = {
    enable = lib.mkEnableOption "Hyprland home config (also enable dotfiles.hyprland in configuration.nix — the two are in separate eval contexts and both must be enabled)";
  };

  config = lib.mkIf (config.dotfiles.hyprland.enable && config.programs.hex.enable) {
    programs.hex.systemdTarget = lib.mkDefault "wayland-session@hyprland.desktop.target";
  };
}
