{
  # Link custom catppuccin theme for Oh-My-Posh
  xdg.configFile."zsh/catppuccin.json".source = ../../config/zsh/catppuccin.json;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = ".config/zsh";
    initExtra =
      # sh
      ''
        ${builtins.readFile ../../config/zsh/extra.zsh}

        # Source secrets
        . ~/.config/zsh/secrets.zsh
      '';

    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;

    history = {
      # append = true;
      ignoreAllDups = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
      size = 5000;
    };

    shellAliases = {
      ls = "ls -ca";
      e = "exit";
      c = "clear";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    tmux.enableShellIntegration = true;
  };
}
