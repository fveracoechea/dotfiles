{
  config,
  pkgs,
  unstable,
  ...
}: {
  imports = [
    ./kitty.nix
  ];

  home.username = "fveracoechea";
  home.homeDirectory = "/home/fveracoechea";

  home.packages = with pkgs; [
    kitty
    ripgrep
    eza
    yazi
    btop
    lazygit
    oh-my-posh
    volta
    fira-code-nerdfont
    neofetch
    python3
    google-chrome
    cmatrix

    # unstable packages
    # unstable.nodejs_22
    unstable.deno
    unstable.neovim

    # scripts
    (writeShellScriptBin "uptime-tmux" (builtins.readFile ../scripts/uptime-tmux.zsh))
    (writeShellScriptBin "git-tmux" (builtins.readFile ../scripts/git-tmux.zsh))
  ];

  programs.git = {
    enable = true;
    userEmail = "veracoecheafrancisco@gmail.com";
    userName = "Francisco Veracoechea";
    extraConfig = {
      pull = {
        rebase = true;
      };
    };
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
      node = "$HOME/.volta/bin/node";
      npm = "$HOME/.volta/bin/npm";
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
      ${(builtins.readFile ../tmux/tmux.extra.conf)}
      ${(builtins.readFile ../tmux/tmux.catppuccin.conf)}
    '';
  };

  # Enable management of XDG base directories
  xdg.enable = true;

  xdg.configFile = {
    "zsh".source = ../zsh;
    # "kitty".source = ../kitty;
    "lazygit".source = ../lazygit;
    "tmux/tmux.extra.conf".source = ../tmux/tmux.extra.conf;
    "tmux/tmux.catppuccin.conf".source = ../tmux/tmux.catppuccin.conf;
    "nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nvim";
      recursive = true;
    };
  };

  # home.file = {};

  home.sessionVariables = {
    VOLTA_HOME = "$HOME/.volta";
  };

  home.sessionPath = [
    "$HOME/.volta/bin"
  ];

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
