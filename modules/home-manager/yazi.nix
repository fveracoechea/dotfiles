{
  lib,
  config,
  pkgs,
  ...
}: let
  theme = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "yazi";
    rev = "baaf5d1c9427b836fbefd126aa855f9eab7a9d0d";
    hash = "sha256-L6SApM07CSQk0znEsFP8WaxW+ZHcindXo612r1XcwIg=";
  };
  themePath =
    theme + "/themes/mocha/catppuccin-mocha-blue.toml";
in {
  options.dotfiles.yazi.enable = lib.mkEnableOption "yazi terminal file manager";

  config = lib.mkIf config.dotfiles.yazi.enable {
    home.packages = with pkgs; [mediainfo];

    programs.yazi = {
      enable = true;
      package = pkgs.yazi;
      enableZshIntegration = true;
      shellWrapperName = "y";

      theme = fromTOML (builtins.readFile themePath);

      plugins = with pkgs.yaziPlugins; {
        inherit git yatline yatline-catppuccin smart-enter smart-filter mediainfo piper;
      };

      initLua =
        # lua
        ''
          require("git"):setup();
          local mocha = require("yatline-catppuccin"):setup("mocha");
          require("yatline"):setup({
            theme = mocha,
          });
        '';

      settings = {
        mgr = {
          show_hidden = true;
          sort_dir_first = true;
          ratio = [1 1 2];

          prepend_keymap = [
            {
              on = "F";
              run = "plugin smart-filter";
              desc = "Smart Filter";
            }
            {
              on = "l";
              run = "plugin smart-enter";
              desc = "Enter the child directory, or open the file";
            }
          ];
        };

        preview = {
          max_width = 1200;
          max_height = 1800;
        };

        tasks = {
          image_alloc = 0; # unlimited
          image_bound = [0 0]; # unlimited
        };

        plugin = {
          prepend_preloaders = [
            {
              mime = "{audio,video,image}/*";
              run = "mediainfo";
            }
            {
              mime = "application/subrip";
              run = "mediainfo";
            }
          ];
          prepend_previewers = [
            {
              mime = "{audio,video,image}/*";
              run = "mediainfo";
            }
            {
              mime = "application/subrip";
              run = "mediainfo";
            }
            {
              url = "*/";
              run = ''piper -- eza -TL=3 --git-ignore --color=always --icons=always --group-directories-first --no-quotes "$1"'';
            }
          ];
          prepend_fetchers = [
            {
              id = "git";
              url = "*";
              run = "git";
              group = "git";
            }
            {
              id = "git";
              url = "*/";
              run = "git";
              group = "git";
            }
          ];
        };
      };
    };
  };
}
