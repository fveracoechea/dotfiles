{ config, pkgs, unstable, lib, ...  }:

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
    neofetch
    python3

    # unstable packages
    # unstable.nodejs_22
    unstable.deno 
    
    # scripts
    (writeShellScriptBin "uptime-tmux"  (builtins.readFile ../../scripts/uptime-tmux.zsh))
    (writeShellScriptBin "git-tmux"  (builtins.readFile ../../scripts/git-tmux.zsh))
  ];

  programs.git = {
    enable = true;
    userEmail = "veracoecheafrancisco@gmail.com";
    userName = "Francisco V";
  };

  programs.neovim = {
    enable = true;
    package = unstable.neovim.unwrapped;
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
      source "${../zsh/extra.zsh}"
    '';
  };

  programs.fzf = {
    enable = true;
    package = unstable.fzf;
    enableZshIntegration = true;
    tmux.enableShellIntegration = true;
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
      tmuxPlugins.resurrect
      tmuxPlugins.continuum
      tmuxPlugins.cpu
      tmuxPlugins.continuum
      tmuxPlugins.catppuccin
    ];

    extraConfig = ''
      source-file "${../tmux/tmux.extra.conf}"
      source-file "${../tmux/tmux.catppuccin.conf}"
    '';
  };

  # Enable management of XDG base directories
  xdg.enable = true;

  xdg.configFile = {
    "kitty".source = ../kitty;
    "nvim".source = ../nvim;
    "zsh".source = ../zsh;
    "tmux/tmux.extra.conf".source = ../tmux/tmux.extra.conf;
    "tmux/tmux.catppuccin.conf".source = ../tmux/tmux.catppuccin.conf;
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
