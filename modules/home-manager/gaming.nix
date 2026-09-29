{
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [./mangohud.nix];

  options.dotfiles.gaming.enable = lib.mkEnableOption "Home gaming tools";

  config = lib.mkIf config.dotfiles.gaming.enable {
    home.packages = with pkgs; [
      mesa-demos
      protonup-rs
      amdgpu_top
      lutris
    ];

    dotfiles.mangohud.enable = lib.mkDefault true;
  };
}
