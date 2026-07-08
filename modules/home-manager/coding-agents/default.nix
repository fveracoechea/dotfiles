{
  lib,
  config,
  ...
}: {
  options.dotfiles.coding-agents.enable = lib.mkEnableOption "OpenCode and Claude";

  config = lib.mkIf config.dotfiles.coding-agents.enable {
    home.file."OPINIONS.md".source = ./OPINIONS.md;
  };

  imports = [./opencode.nix ./claude-code.nix];
}
