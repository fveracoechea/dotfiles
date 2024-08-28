{
  config,
  pkgs,
  unstable,
  ...
}: {
  imports = [
    ../../modules/home-manager/kitty.nix
    ../../modules/home-manager/hyprland.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/tmux.nix
    ../../modules/home-manager/zsh.nix
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
    unstable.deno
    unstable.neovim
    # scripts
    (writeShellScriptBin "uptime-tmux" (builtins.readFile ../../../scripts/uptime-tmux.zsh))
    (writeShellScriptBin "git-tmux" (builtins.readFile ../../../scripts/git-tmux.zsh))
  ];

  programs.fzf = {
    enable = true;
    package = unstable.fzf;
    enableZshIntegration = true;
    tmux.enableShellIntegration = true;
  };

  # Enable management of XDG base directories
  xdg.enable = true;

  xdg.configFile = {
    "zsh".source = ../../../zsh;
    # "kitty".source = ../kitty;
    "lazygit".source = ../../../lazygit;
    "tmux/tmux.extra.conf".source = ../../../tmux/tmux.extra.conf;
    "tmux/tmux.catppuccin.conf".source = ../../../tmux/tmux.catppuccin.conf;
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
