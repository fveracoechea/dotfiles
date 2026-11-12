{
  inputs,
  stablePkgsFor,
}: {pkgs, ...}: {
  _module.args = {
    codingAgentPkgs = pkgs;
    codingAgentSources = {
      inherit (inputs) herdr hunk operator operator-agents;
    };
    codingAgentPackages = import ../../packages {inherit inputs pkgs;};
    codingAgentMcpPackage = (stablePkgsFor pkgs.stdenv.hostPlatform.system).mcp-nixos;
  };
}
