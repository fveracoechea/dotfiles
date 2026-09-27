{
  lib,
  config,
  pkgs,
  ...
}: let
  # gh hides its token in the keyring, so `hunk gh` never sees it. The guard
  # keeps that keyring read off the hot `hunk pager` path.
  hunk = pkgs.symlinkJoin {
    name = "hunk-${pkgs.hunk.version}";
    paths = [pkgs.hunk];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/hunk \
        --run 'if [ "$1" = "gh" ] && [ -z "$GH_TOKEN" ] && [ -z "$GITHUB_TOKEN" ]; then export GH_TOKEN=$(${pkgs.gh}/bin/gh auth token 2>/dev/null); fi'
    '';
  };
in {
  config = lib.mkIf config.dotfiles.coding-agents.enable {
    home.packages = [hunk pkgs.gh];

    xdg.configFile."hunk/extensions/hunk-gh".source = pkgs.fetchFromGitHub {
      owner = "modem-dev";
      repo = "hunk-gh";
      rev = "bdf6f9613f575b286d3af6edafc733249e933ddf";
      hash = "sha256-rlwDga40MWhLm90LAZNQlH10aD7lZx2aGnIXijFFMlM=";
    };

    xdg.configFile."hunk/config.toml".source = (pkgs.formats.toml {}).generate "hunk-config" {
      theme = "catppuccin-mocha";
      mode = "stack";
      line_numbers = true;
      warp_lines = false;
      transparent_background = true;
      hunk_headers = false;
      # Hunk's automatic discovery skips symlinked extension directories.
      extensions.paths = ["${config.xdg.configHome}/hunk/extensions/hunk-gh"];
    };

    programs.git.settings.core.pager = "hunk pager";
    programs.lazygit.settings.git.diffRenderers = [{command = "hunk pager";}];
  };
}
