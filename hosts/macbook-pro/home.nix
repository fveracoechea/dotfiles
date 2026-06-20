{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/home-manager/default.nix
    inputs.neovim-config.homeManagerModules.default
  ];

  dotfiles.bat.enable = true;

  home.packages = with pkgs; [
    watchman
    ripgrep
    wget
    lazydocker
    just
    wireguard-tools
    agent-browser
    glab
    redis
    claude-code
  ];

  # home.username = "franciscoveracoechea";
  # home.homeDirectory = /Users/franciscoveracoechea;

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
