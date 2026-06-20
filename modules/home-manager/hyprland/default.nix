{
  lib,
  config,
  ...
}: {
  imports = [
    ./settings.nix
    ./bindings.nix
    ./env.nix
    ./packages.nix
    ./windowrules.nix
    ./hypridle.nix
    ./hyprlock.nix
    ./hyprpaper.nix
    ./hyprcursor.nix
    ./theme.nix
  ];

  options.dotfiles.hyprland.enable = lib.mkEnableOption "Hyprland home config (also enable dotfiles.hyprland in configuration.nix — the two are in separate eval contexts and both must be enabled)";
}
