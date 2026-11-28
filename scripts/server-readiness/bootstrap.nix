{
  deployedFlake,
  host,
  selector,
  nixpkgsInput ? "nixpkgs",
}:
assert builtins.match "github:[^/]+/[^/]+/[a-f0-9]{40}" deployedFlake != null;
let
  deployed = builtins.getFlake deployedFlake;
  system = deployed.nixosConfigurations.${selector};
in
{
  source = deployedFlake;
  reviewedBy = "";
  systemPath = system.config.system.build.toplevel.outPath;
  manifest = import ./manifest.nix {
    inherit host;
    inherit (system) pkgs config options;
    lib = system.pkgs.lib;
    source = {
      input = "nixpkgs-servers";
      kind = "preserved";
      channel = null;
      revision = deployed.inputs.${nixpkgsInput}.rev;
    };
  };
}
