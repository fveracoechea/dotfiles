{
  lib,
  config,
  pkgs,
  ...
}: {
  options.dotfiles.git.enable = lib.mkEnableOption "git";

  config = lib.mkIf config.dotfiles.git.enable {
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
    };
  };
}
