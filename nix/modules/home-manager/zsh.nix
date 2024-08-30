{
  # Link custom catppuccin theme for Oh-My-Posh
  xdg.configFile."zsh/catppuccin.json".source = ../../../zsh/catppuccin.json;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    initExtra = builtins.readFile ../../../zsh/extra.zsh;
    # dotDir = ".config/zsh";

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
      ls = "ls -lca";
      e = "exit";
      c = "clear";
      node = "$HOME/.volta/bin/node";
      npm = "$HOME/.volta/bin/npm";
    };
  };
}