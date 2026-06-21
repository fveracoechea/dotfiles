{lib, config, pkgs, ...}: {
  options.dotfiles.bat.enable = lib.mkEnableOption "bat (cat clone with syntax highlighting)";

  config = lib.mkIf config.dotfiles.bat.enable {
    programs.bat = {
      enable = true;

      config = {
        theme = "Catppuccin Mocha";
      };

      syntaxes = {
        gleam = {
          src = pkgs.fetchFromGitHub {
            owner = "molnarmark";
            repo = "sublime-gleam";
            rev = "ff9638511e05b0aca236d63071c621977cffce38";
            hash = "sha256-94moZz9r5cMVPWTyzGlbpu9p2p/5Js7/KV6V4Etqvbo=";
          };
          file = "syntax/gleam.sublime-syntax";
        };
      };

      # Bat uses sublime syntax for its themes
      themes = {
        dracula = {
          src = pkgs.fetchFromGitHub {
            owner = "dracula";
            repo = "sublime";
            rev = "456d3289827964a6cb503a3b0a6448f4326f291b";
            hash = "sha256-8mCovVSrBjtFi5q+XQdqAaqOt3Q+Fo29eIDwECOViro=";
          };
          file = "Dracula.tmTheme";
        };

        catppuccinMocha = {
          src = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "bat";
            rev = "699f60fc8ec434574ca7451b444b880430319941";
            hash = "sha256-6fWoCH90IGumAMc4buLRWL0N61op+AuMNN9CAR9/OdI=";
          };
          file = "themes/Catppuccin Mocha.tmTheme";
        };
      };
    };
  };
}
