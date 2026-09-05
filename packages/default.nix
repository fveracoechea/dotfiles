# Custom Packages and flake-input wrappers. Consumers read `dotfilesPkgs.<name>`
# so no call site touches `inputs` or the host system directly. All entries use
# the latest channel `pkgs`.
{
  pkgs,
  inputs,
}: {
  dev-manager-desktop = pkgs.callPackage ./dev-manager-desktop.nix {};
  stylelint-language-server = pkgs.callPackage ./stylelint-language-server.nix {};

  herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
  tmux-powerkit = inputs.tmux-powerkit.packages.${pkgs.stdenv.hostPlatform.system}.default;
  ultrashell = inputs.ultrashell.packages.${pkgs.stdenv.hostPlatform.system}.default;
}
