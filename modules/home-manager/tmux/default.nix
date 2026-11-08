{
  lib,
  config,
  pkgs,
  pkgs-stable,
  dotfilesPkgs,
  ...
}: {
  options.dotfiles.tmux.enable = lib.mkEnableOption "tmux terminal multiplexer";

  config = lib.mkIf config.dotfiles.tmux.enable {
    programs.tmux = {
      enable = true;
      keyMode = "vi";
      terminal = "tmux-256color";
      mouse = true;
      baseIndex = 1;
      focusEvents = true;
      historyLimit = 50000;
      # Match the System's registered login shell. See ADR-0007.
      shell = "${pkgs-stable.zsh}/bin/zsh";
      extraConfig = lib.fileContents ./tmux.conf;
      plugins = with pkgs; [
        tmuxPlugins.vim-tmux-navigator
        {
          plugin = dotfilesPkgs.tmux-powerkit;
          extraConfig = lib.fileContents ./tmux.powerkit.conf;
        }
      ];
    };
  };
}
