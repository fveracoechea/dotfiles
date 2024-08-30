{pkgs, ...}: {
  imports = [
    ../../modules/home-manager/kitty.nix
    ../../modules/home-manager/hyprland.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/tmux.nix
    ../../modules/home-manager/zsh.nix
    ../../modules/home-manager/xdg.nix
    ../../modules/home-manager/gnome.nix
    ../../modules/home-manager/dconf.nix
  ];

  home.username = "fveracoechea";
  home.homeDirectory = "/home/fveracoechea";

  # scripts
  home.packages = with pkgs; [
    (writeShellScriptBin "uptime-tmux" (builtins.readFile ../../../scripts/uptime-tmux.zsh))
    (writeShellScriptBin "git-tmux" (builtins.readFile ../../../scripts/git-tmux.zsh))
  ];

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    tmux.enableShellIntegration = true;
  };

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
