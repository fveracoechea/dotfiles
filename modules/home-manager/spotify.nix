{
  lib,
  config,
  inputs,
  pkgs,
  ...
}: let
  themeRepo = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "spicetify";
    rev = "1ec645c4cf7f42f9792b9eeb1bb7930f94593277";
    hash = "sha256-VK9JpXYFuLMkIuMftFkkMy6Y5+ttuxDUYoIiAPlx6YY=";
  };
in {
  imports = [
    inputs.spicetify-nix.homeManagerModules.default
  ];

  options.dotfiles.spotify.enable = lib.mkEnableOption "Spotify with spicetify-nix";

  config = lib.mkIf config.dotfiles.spotify.enable {
    programs.cava.enable = true;

    programs.spicetify = {
      enable = true;
      colorScheme = "mocha";
      theme = {
        name = "catppuccin";
        src = "${themeRepo}/catppuccin";
        injectCss = true;
        injectThemeJs = true;
        replaceColors = true;
        overwriteAssets = true;
      };
    };
  };
}
