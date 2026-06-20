{...}: {
  imports = [
    ../core/palette.nix
    ../core/monitors.nix

    ./bootloader.nix
    ./display-manager.nix
    ./gaming.nix
    ./hyprland.nix
    ./misc.nix
    ./networking.nix
    ./nix-ld.nix
    ./ollama.nix
    ./pipewire.nix
    ./timezone.nix
    ./zsh-shell.nix
  ];
}
