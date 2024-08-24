{ config, pkgs, ...  }:

{
  home.username = "fveracoechea";
  home.homeDirectory = "/home/fveracoechea";

  home.packages = with pkgs; [
    zip
    unzip
    kitty
    ripgrep
    fzf
    eza
    yazi
    btop
    stow
    lazygit
    oh-my-posh
    volta
    fira-code-nerdfont
    gnumake
  ];

  programs.git.enable = true;
  
  programs.neovim.enable = true;

  programs.tmux.enable = true;

  # Enable management of XDG base directories
  xdg.enable = true;

  xdg.configFile = {
    "kitty".source = ../kitty;
    "nvim".source = ../nvim;
    "tmux".source = ../tmux;
    "zsh".source = ../zsh;
    "git".source = ../git;
    "lazygit".source = ../lazygit;
  };

  home.file = {
    ".zshrc".source = ../zsh/init.zsh;
  };

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
