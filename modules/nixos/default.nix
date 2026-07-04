{...}: {
  imports = [
    ../core/palette.nix

    ./bootloader.nix
    ./display-manager.nix
    ./tailscale-client.nix
    ./docker.nix
    ./gaming.nix
    ./hyprland.nix
    ./networking.nix
    ./nix-ld.nix
    ./pipewire.nix
    ./timezone.nix
    ./system-shell.nix
  ];
}
