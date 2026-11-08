{
  inputs,
  stablePkgsFor,
}: {pkgs, ...}: {
  _module.args = {
    codingAgentSources = {
      inherit (inputs) herdr hunk operator;
    };
    codingAgentPackages = import ./packages.nix {inherit inputs pkgs;};
    codingAgentMcpPackage = (stablePkgsFor pkgs.stdenv.hostPlatform.system).mcp-nixos;
  };
}
