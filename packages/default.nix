# Custom Packages and flake-input wrappers. Consumers read `dotfilesPkgs.<name>`
# so no call site touches `inputs` or the host system directly. All entries use
# the latest channel `pkgs`.
{
  pkgs,
  inputs,
}: {
  dev-manager-desktop = inputs.dev-manager-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default;
  herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
  herdr-nvim = pkgs.callPackage ./herdr-nvim.nix {};
  operator = inputs.operator.packages.${pkgs.stdenv.hostPlatform.system}.default;
  railway = pkgs.callPackage ./railway.nix {};

  tmux-powerkit = inputs.tmux-powerkit.packages.${pkgs.stdenv.hostPlatform.system}.default;
}
