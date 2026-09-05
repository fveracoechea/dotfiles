{
  lib,
  config,
  pkgs,
  ...
}: {
  options.dotfiles.git.enable = lib.mkEnableOption "git (with hunk pager)";

  config = let
    tomlFormat = pkgs.formats.toml {};
  in
    lib.mkIf config.dotfiles.git.enable {
      home.packages = with pkgs; [hunk gh];

      xdg.configFile."hunk/config.toml".source = tomlFormat.generate "hunk-config" {
        theme = "auto";
        mode = "auto";
        line_numbers = true;
        warp_lines = false;
        transparent_background = true;
        hunk_headers = false;
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
