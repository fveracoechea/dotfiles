{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  options.dotfiles.git.enable = lib.mkEnableOption "git (with hunk pager)";

  config = let
    tomlFormat = pkgs.formats.toml {};
    hunkPacakge = inputs.hunk.packages.${pkgs.system}.default;
  in
    lib.mkIf config.dotfiles.git.enable {
      home.packages = [hunkPacakge pkgs.gh];

      xdg.configFile."hunk/config.toml".source = tomlFormat.generate "hunk-config" {
        theme = "auto";
        mode = "auto";
        line_numbers = true;
        warp_lines = false;
        transparent_background = true;
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
            sshCommand = "ssh -i ~/.ssh/id_github_hypr";
            pager = "hunk pager";
          };
          pull = {
            rebase = true;
          };
          rebase = {
            autosquash = true;
          };
          credential = lib.mkIf pkgs.stdenv.isDarwin {
            helper = "osxkeychain";
          };
        };
      };

      programs.lazygit = {
        enable = true;
        enableZshIntegration = true;
        settings.git.pagers = [{pager = "hunk pager";}];
      };
    };
}
