{
  lib,
  config,
  ...
}: {
  imports = [./home-base.nix];

  config = lib.mkIf config.dotfiles.coding-agents.enable {
    programs.opencode = {
      cli = import ./cli.nix;
      validateFiles = {
        config = true;
        cli = true;
      };
    };
  };
}
