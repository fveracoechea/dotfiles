{
  pkgs,
  inputs,
}: {
  dev-manager-desktop = pkgs.callPackage ./dev-manager-desktop.nix {};
  railway = pkgs.callPackage ./railway.nix {};

  hyprland = inputs.hyprland.packages.${pkgs.system}.hyprland;
  hyprland-portal = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  tmux-powerkit = inputs.tmux-powerkit.packages.${pkgs.system}.default;
  ultrashell = inputs.ultrashell.packages.${pkgs.system}.default;
  hunk = inputs.hunk.packages.${pkgs.system}.default;
}
