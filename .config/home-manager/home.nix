{ config, pkgs, pkgs-unstable, lib, ...  }:

{
  home.username = "fveracoechea";
  home.homeDirectory = "/home/fveracoechea";

  home.packages = with pkgs; [
    zip
    unzip
    kitty
    ripgrep
    eza
    yazi
    btop
    stow
    lazygit
    oh-my-posh
    volta
    fira-code-nerdfont
    gnumake

    # unstable packages
    pkgs-unstable.nodejs_22
    pkgs-unstable.deno
  ];

  programs.git = {
    enable = true;
    userEmail = "veracoecheafrancisco@gmail.com";
    userName = "Francisco V";
  };

  programs.neovim = {
    enable = true;
    package = pkgs-unstable.neovim.unwrapped;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
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
    };

    initExtra = ''
      # Completion styling
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

      # Run oh-my-posh
      eval "$(oh-my-posh init zsh --config $XDG_CONFIG_HOME/oh-my-posh/catppuccin.json)"
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    tmux.enableShellIntegration = true;
  };


  programs.tmux = {
    enable = true;
    shell = "\${pkgs.zsh}/bin/zsh";
    keyMode = "vi";
    mouse = true;
    terminal = "screen-256color";
    baseIndex = 1;
  };

  # Enable management of XDG base directories
  xdg.enable = true;

  xdg.configFile = {
    "kitty".source = ../kitty;
    "nvim".source = ../nvim;
    "tmux".source = ../tmux;
    "oh-my-posh".source = ../oh-my-posh;
    "git".source = ../git;
    "lazygit".source = ../lazygit;
  };

  # xdg.configFile."tmux/tmux.conf".enable = false;

  home.file = {
    # ".zshrc".source = ../zsh/init.zsh;
  };

  # home.sessionVariables = {
  #   NIX_LD_LIBRARY_PATH =
  #     lib.makeLibraryPath (with pkgs; [ stdenv.cc.cc openssl ]);
  #   NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
  # };

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.05";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;

}
