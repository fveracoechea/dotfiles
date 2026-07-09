{
  lib,
  config,
  pkgs,
  dotfilesPkgs,
  ...
}: {
  options.dotfiles.coding-agents.enable = lib.mkEnableOption "OpenCode and Claude";

  config = lib.mkIf config.dotfiles.coding-agents.enable {
    home.file."OPINIONS.md".source = ./OPINIONS.md;

    home.packages = with pkgs; [
      nixd
      lua-language-server
      biome
      dotfilesPkgs.stylelint-language-server
    ];
  };

  imports = [./opencode.nix ./claude-code.nix ./herdr.nix];
}
