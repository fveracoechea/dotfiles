{unstable, ...}: {
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
      tmuxPlugins.resurrect
      tmuxPlugins.continuum
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
