{
  lib,
  config,
  pkgs,
  codingAgentPkgs ? pkgs,
  codingAgentPackages,
  codingAgentSources,
  codingAgentMcpPackage,
  ...
}:
let
  opencode = import ./opencode.nix {
    inherit
      lib
      codingAgentPkgs
      codingAgentPackages
      codingAgentSources
      codingAgentMcpPackage
      ;
  };
in
{
  imports = [
    ./herdr.nix
    ./hunk.nix
  ];

  options.dotfiles.coding-agents.enable = lib.mkEnableOption "Home coding agents with Herdr, OpenCode, Operator, Hunk, and language tooling";

  config = lib.mkIf config.dotfiles.coding-agents.enable {
    xdg.configFile."opencode/plugins/operator.ts".source =
      "${codingAgentPackages.operator}/share/opencode/plugins/operator.ts";
    xdg.configFile."opencode/agents/super.md".source =
      "${codingAgentSources.operator-agents}/agents/opencode/super.md";
    xdg.configFile."opencode/agents/worker.md".source =
      "${codingAgentSources.operator-agents}/agents/opencode/worker.md";
    home.packages = with codingAgentPkgs; [
      codingAgentPackages.operator
      python3
      nixd
      nixfmt
      typescript-language-server
      oxfmt
      lsof
      # Latest depends on broken fastmcp-slim. Return when its MCP 2 support is fixed.
      codingAgentMcpPackage
    ];

    programs.opencode = {
      enable = true;
      context = "${codingAgentSources.operator}/agents/AGENTS.md";
      inherit (opencode) skills;
      settings = opencode.settings // {
        model = lib.mkDefault opencode.settings.model;
      };
      cli = import ./cli.nix;
      validateFiles = {
        config = true;
        cli = true;
      };
    };
  };
}
