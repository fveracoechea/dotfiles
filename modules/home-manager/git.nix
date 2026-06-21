{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  options.dotfiles.git.enable = lib.mkEnableOption "git (with hunk pager)";

  config = lib.mkIf config.dotfiles.git.enable {
    home.packages = [ inputs.hunk.packages.${pkgs.system}.default ];

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
      settings.git.paging.pager = "hunk pager";
    };
  };
}
