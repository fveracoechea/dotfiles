{
  pkgs,
  inputs,
  system,
}: {
  dev-manager-desktop = pkgs.callPackage ./dev-manager-desktop.nix {};
  railway = pkgs.callPackage ./railway.nix {};

  hyprland = inputs.hyprland.packages.${system}.hyprland;
  hyprland-portal = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
  tmux-powerkit = inputs.tmux-powerkit.packages.${system}.default;
  ultrashell = inputs.ultrashell.packages.${system}.default;
}
