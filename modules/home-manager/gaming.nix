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
      protonup-ng
      amdgpu_top
    ];

    dotfiles.mangohud.enable = lib.mkDefault true;
  };
}
