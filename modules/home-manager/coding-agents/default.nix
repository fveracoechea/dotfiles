{
  lib,
  config,
  pkgs,
  dotfilesPkgs,
  ...
}: {
  options.dotfiles.coding-agents.enable = lib.mkEnableOption "OpenCode";

  config = lib.mkIf config.dotfiles.coding-agents.enable {
    home.packages = with pkgs; [
      dotfilesPkgs.operator
      python3
      nixd
      typescript-language-server
      biome
      oxfmt
    ];
  };

  imports = [./opencode.nix ./herdr.nix ./hunk.nix];
}
