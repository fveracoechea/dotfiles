{
  unstable,
  pkgs,
  ...
}: let
  settings = {
    tmux = builtins.readFile ../../../tmux/tmux.conf;
    catppuccin = builtins.readFile ../../../tmux/tmux.catppuccin.conf;
    tmux-clima = pkgs.tmuxPlugins.mkTmuxPlugin {
      pluginName = "tmux-clima";
      version = "unstable-2024-08-26";
      src = pkgs.fetchFromGitHub {
        owner = "vascomfnunes";
        repo = "tmux-clima";
        rev = "fbfad234b06e2040dbbcbde9451b30fa43d81523";
        hash = "sha256-EmwCOfT6dIEmG34cj5oKMs1/loyrwOYWsHY6T+xNSCg=";
      };
    };
  };
in {
  programs.tmux = {
    enable = true;
    package = unstable.tmux;
    keyMode = "vi";
    mouse = true;
    terminal = "screen-256color";
    baseIndex = 1;
    extraConfig = settings.tmux;

    plugins = with unstable; [
      tmuxPlugins.vim-tmux-navigator
      tmuxPlugins.yank
      tmuxPlugins.cpu
      {
        plugin = tmuxPlugins.catppuccin;
        extraConfig = settings.catppuccin;
      }
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-save-interval '5'
        '';
      }
      {
        plugin = settings.tmux-clima;
        extraConfig = ''
          set -g @clima_unit imperial
          set -g @clima_use_nerd_font 1
        '';
      }
    ];
  };
}
