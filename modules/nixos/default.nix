{ ... }: {
  imports = [
    ../core/palette.nix

    ./bootloader.nix
    ./crash-capture.nix
    ./display-manager.nix
    ./tailscale-client.nix
    ./docker.nix
    ../gaming/nixos.nix
    ../hyprland/nixos.nix
    ../networking/nixos.nix
    ./nix-ld.nix
    ../audio/nixos.nix
    ./timezone.nix
    ../shell/nixos.nix
  ];
}
