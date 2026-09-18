{
  lib,
  config,
  pkgs,
  ...
}: {
  options.dotfiles.git.enable = lib.mkEnableOption "git (with hunk pager)";

  config = let
    tomlFormat = pkgs.formats.toml {};

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
  in
    lib.mkIf config.dotfiles.git.enable {
      home.packages = [hunk pkgs.gh];

      xdg.configFile."hunk/extensions/hunk-diff-context".source = pkgs.fetchFromGitHub {
        owner = "astwys";
        repo = "hunk-diff-context";
        rev = "d515e0a25309cbdcd90a2fed879ddc73f4599c72";
        hash = "sha256-ZvIpNUOyIWFAFkeBRxi4IA0JnKI2fSXm4udOYFopZkk=";
      };

      xdg.configFile."hunk/extensions/hunk-gh".source = pkgs.fetchFromGitHub {
        owner = "modem-dev";
        repo = "hunk-gh";
        rev = "bdf6f9613f575b286d3af6edafc733249e933ddf";
        hash = "sha256-rlwDga40MWhLm90LAZNQlH10aD7lZx2aGnIXijFFMlM=";
      };

      xdg.configFile."hunk/config.toml".source = tomlFormat.generate "hunk-config" {
        theme = "catppuccin-mocha";
        mode = "auto";
        line_numbers = true;
        warp_lines = false;
        transparent_background = true;
        hunk_headers = false;
        # Hunk's automatic discovery skips symlinked extension directories.
        extensions.paths = [
          "${config.xdg.configHome}/hunk/extensions/hunk-diff-context"
          "${config.xdg.configHome}/hunk/extensions/hunk-gh"
        ];
      };

      programs.git = {
        enable = true;
        signing.format = "openpgp";

        settings = {
          user = {
            email = "veracoecheafrancisco@gmail.com";
            name = "Francisco Veracoechea";
          };
          core = {
            editor = "nvim";
            pager = "hunk pager";
          };
          pull = {
            rebase = true;
          };
          rebase = {
            autosquash = true;
          };
          credential = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
            helper = "osxkeychain";
          };
        };
      };

      programs.lazygit = {
        enable = true;
        enableZshIntegration = true;
        settings.git.diffRenderers = [{command = "hunk pager";}];
      };
    };
}
