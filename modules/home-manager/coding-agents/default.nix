{
  lib,
  config,
  pkgs,
  ...
}: {
  options.dotfiles.coding-agents.enable = lib.mkEnableOption "OpenCode";

  config = lib.mkIf config.dotfiles.coding-agents.enable {
    home.file."OPINIONS.md".source = ./OPINIONS.md;

    home.packages = with pkgs; [
      python3
      nixd
      typescript-language-server
      biome
      oxfmt
    ];
  };

  imports = [./opencode.nix ./herdr.nix ./hunk.nix];
}
