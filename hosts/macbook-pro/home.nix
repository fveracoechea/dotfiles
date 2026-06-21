{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/home-manager/default.nix
    inputs.neovim-config.homeManagerModules.default
  ];

  dotfiles = {
    shell.enable = true;
    volta.enable = true;
    ghostty.enable = true;
    fonts.enable = true;
    karabiner.enable = true;
    ssh.enable = true;
    # aerospace.enable = true;
    opencode.enable = true;
  };

  home.packages = with pkgs; [
    watchman
    ripgrep
    wget
    just
    wireguard-tools
    agent-browser
    glab
    redis
    claude-code
  ];

  # DO NOT CHANGE
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
