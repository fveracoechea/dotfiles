{
  pkgs,
  lib,
  ...
}: let
  settings = {
    tmux = lib.fileContents ../../config/tmux/tmux.conf;
    catppuccin = lib.fileContents ../../config/tmux/tmux.catppuccin.conf;
  };
in {
  # scripts
  home.packages = with pkgs; [
    (writeShellScriptBin "uptime-tmux" (lib.fileContents ../../config/scripts/uptime-tmux.zsh))
    (writeShellScriptBin "git-tmux" (lib.fileContents ../../config/scripts/git-tmux.zsh))
  ];

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    mouse = true;
    terminal = "screen-256color";
    baseIndex = 1;
    extraConfig = settings.tmux;

    plugins = with pkgs; [
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
    ];
  };
}
