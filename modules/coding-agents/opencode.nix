{
  codingAgentSources,
  lib,
  config,
  pkgs,
  codingAgentPkgs ? pkgs,
  codingAgentMcpPackage,
  codingAgentPackages,
  ...
}: let
  settings = import ./settings.nix {inherit lib codingAgentMcpPackage;};
in {
  config = lib.mkIf config.dotfiles.coding-agents.enable {
    xdg.configFile."opencode/plugins/operator.ts".source = "${codingAgentPackages.operator}/share/opencode/plugins/operator.ts";
    home.packages = with codingAgentPkgs; [
      lsof
      # Latest depends on broken fastmcp-slim. Return when its MCP 2 support is fixed.
      codingAgentMcpPackage
    ];
    programs.opencode = {
      enable = true;
      context = "${codingAgentSources.operator}/agents/AGENTS.md";
      skills = import ./skills.nix {inherit lib codingAgentPackages codingAgentSources;};
      settings = settings // {model = lib.mkDefault settings.model;};
    };
  };
}
