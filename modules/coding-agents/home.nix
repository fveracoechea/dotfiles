{
  lib,
  config,
  pkgs,
  codingAgentPkgs ? pkgs,
  codingAgentPackages,
  ...
}:
{
  imports = [
    ./opencode.nix
    ./herdr.nix
    ./hunk.nix
  ];

  options.dotfiles.coding-agents.enable = lib.mkEnableOption "Home coding agents with Herdr, OpenCode, Operator, Hunk, and language tooling";

  config = lib.mkIf config.dotfiles.coding-agents.enable {
    home.packages = with codingAgentPkgs; [
      codingAgentPackages.operator
      python3
      nixd
      nixfmt
      typescript-language-server
      oxfmt
    ];

    programs.opencode = {
      cli = import ./cli.nix;
      validateFiles = {
        config = true;
        cli = true;
      };
    };
  };
}
