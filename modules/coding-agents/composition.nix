# flake.nix supplies inputs first; Home Manager then supplies pkgs.
# _module.args makes these dependencies available to the coding-agent modules
# without replacing the Home's pkgs. See docs/homelab-coding-agents.md.
{
  inputs,
  stablePkgsFor,
}:
{ pkgs, ... }: {
  _module.args = {
    codingAgentPkgs = pkgs;
    codingAgentSources = {
      inherit (inputs)
        herdr
        hunk
        operator
        operator-agents
        ;
    };
    codingAgentPackages = import ../../packages { inherit inputs pkgs; };
    # Channel Hold: the Latest Channel failure is documented in opencode.nix.
    codingAgentMcpPackage = (stablePkgsFor pkgs.stdenv.hostPlatform.system).mcp-nixos;
  };
}
