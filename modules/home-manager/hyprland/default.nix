{lib, ...}: {
  imports = [
    ./settings.nix
    ./packages.nix
    ./hypridle.nix
    ./hyprlock.nix
    ./hyprpaper.nix
    ./hyprcursor.nix
  ];

  options.dotfiles.hyprland = {
    enable = lib.mkEnableOption "Hyprland home config (also enable dotfiles.hyprland in configuration.nix — the two are in separate eval contexts and both must be enabled)";

    monitors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''Monitor spec strings for the active host (e.g. "DP-1, 5120x1440@119.98Hz, auto, auto, bitdepth, 8, cm, auto").'';
    };
  };
}
