{unstable, ...}: {
  # link config files
  xdg.configFile = {
    "tmux/tmux.extra.conf".source = ../../../tmux/tmux.extra.conf;
    "tmux/tmux.catppuccin.conf".source = ../../../tmux/tmux.catppuccin.conf;
  };

  programs.tmux = {
    enable = true;
    package = unstable.tmux;
    keyMode = "vi";
    mouse = true;
    terminal = "screen-256color";
    baseIndex = 1;

    plugins = with unstable; [
      tmuxPlugins.vim-tmux-navigator
      tmuxPlugins.yank
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
      tmuxPlugins.cpu
      tmuxPlugins.continuum
      tmuxPlugins.catppuccin
    ];

    extraConfig = ''
      ${(builtins.readFile ../../../tmux/tmux.extra.conf)}
      ${(builtins.readFile ../../../tmux/tmux.catppuccin.conf)}
    '';
  };
}
