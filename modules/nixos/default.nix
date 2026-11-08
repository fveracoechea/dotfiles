{...}: {
  imports = [
    ../core/palette.nix

    ./bootloader.nix
    ./crash-capture.nix
    ./display-manager.nix
    ./tailscale-client.nix
    ./docker.nix
    ./gaming.nix
    ./hyprland.nix
    ../networking/nixos.nix
    ./nix-ld.nix
    ./pipewire.nix
    ./timezone.nix
    ../shell/nixos.nix
  ];
}
