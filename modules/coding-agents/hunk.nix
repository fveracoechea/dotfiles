{
  lib,
  config,
  pkgs,
  codingAgentPkgs ? pkgs,
  codingAgentSources,
  ...
}:
let
  agentPkgs = codingAgentPkgs;
  hunkPackage = codingAgentSources.hunk.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # gh hides its token in the keyring, so `hunk gh` never sees it. The guard
  # keeps that keyring read off the hot `hunk pager` path.
  hunk = agentPkgs.symlinkJoin {
    name = "hunk-${hunkPackage.version}";
    paths = [ hunkPackage ];
    nativeBuildInputs = [ agentPkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/hunk \
        --run 'if [ "$1" = "gh" ] && [ -z "$GH_TOKEN" ] && [ -z "$GITHUB_TOKEN" ]; then export GH_TOKEN=$(${agentPkgs.gh}/bin/gh auth token 2>/dev/null); fi'
    '';
  };
in
{
  config = lib.mkIf config.dotfiles.coding-agents.enable {
    home.packages = [
      hunk
      agentPkgs.gh
    ];

    xdg.configFile."hunk/extensions/hunk-gh".source = agentPkgs.fetchFromGitHub {
      owner = "modem-dev";
      repo = "hunk-gh";
      rev = "bdf6f9613f575b286d3af6edafc733249e933ddf";
      hash = "sha256-rlwDga40MWhLm90LAZNQlH10aD7lZx2aGnIXijFFMlM=";
    };

    xdg.configFile."hunk/config.toml".source = (agentPkgs.formats.toml { }).generate "hunk-config" (
      import ./hunk-settings.nix config.xdg.configHome
    );

    programs.git.settings.core.pager = lib.mkIf config.programs.git.enable "hunk pager";
    programs.lazygit.settings.git.diffRenderers = lib.mkIf config.programs.lazygit.enable [
      { command = "hunk pager"; }
    ];
  };
}
