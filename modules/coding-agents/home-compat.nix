{
  inputs,
  agentPkgs,
  stablePkgsFor,
}: {
  lib,
  config,
  pkgs,
  dotfilesPkgs,
  codingAgentPackages,
  codingAgentSources,
  ...
}: {
  # ADR-0008: remove only the frozen agent subtree, not the compatibility Home.
  disabledModules = ["${inputs.server-dotfiles-compat}/modules/home-manager/coding-agents"];
  imports = [./home-base.nix];

  options.home.packages = lib.mkOption {
    apply = packages:
      if config.dotfiles.coding-agents.enable
      then builtins.filter (package: !(builtins.elem (toString package) (map toString [dotfilesPkgs.hunk pkgs.gh]))) packages
      else packages;
  };

  config = lib.mkMerge [
    {
      _module.args = {
        codingAgentPkgs = agentPkgs;
        codingAgentSources = lib.mkForce {inherit (inputs) herdr hunk operator operator-agents;};
        codingAgentPackages = import ../../packages {
          inherit inputs;
          pkgs = agentPkgs;
        };
        codingAgentMcpPackage = (stablePkgsFor agentPkgs.stdenv.hostPlatform.system).mcp-nixos;
      };
    }

    (lib.mkIf config.dotfiles.coding-agents.enable {
      programs.opencode.package = agentPkgs.opencode;
      programs.opencode.context = lib.mkForce "";
      # The old renderer probes unrealized package directories during evaluation.
      programs.opencode.skills = lib.mkForce {};
      xdg.configFile =
        lib.mapAttrs' (name: source:
          lib.nameValuePair "opencode/skills/${name}" {
            inherit source;
            recursive = true;
          }) (import ./skills.nix {inherit lib codingAgentPackages codingAgentSources;})
        // {
          "opencode/AGENTS.md".source = "${inputs.operator}/agents/AGENTS.md";
          "opencode/cli.json".source = let
            json = (agentPkgs.formats.json {}).generate "cli.json" (
              {"$schema" = "https://opencode.ai/v2/cli.json";} // import ./cli.nix
            );
          in
            agentPkgs.runCommand "opencode-cli.json" {nativeBuildInputs = [agentPkgs.check-jsonschema];} ''
              check-jsonschema --force-filetype=json --schemafile=${agentPkgs.opencode.jsonschema.cli} ${json}
              cp ${json} "$out"
            '';
          "hunk/config.toml".source = lib.mkForce ((agentPkgs.formats.toml {}).generate "hunk-config" (import ./hunk-settings.nix config.xdg.configHome));
        };
      programs.lazygit.settings.git.diffRenderers = lib.mkIf config.programs.lazygit.enable (lib.mkForce [{command = "hunk pager";}]);
    })
  ];
}
