{
  inputs,
  lib,
  ...
}: {
  imports = [
    ../../modules/home-manager/kitty.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/tmux.nix
    ../../modules/home-manager/zsh.nix
    ../../modules/home-manager/gnome.nix
    ../../modules/home-manager/dconf.nix
    ../../modules/home-manager/volta.nix
    ../../modules/home-manager/pro-audio.nix
    ../../modules/home-manager/spotify.nix
    ../../modules/home-manager/hyprland.nix
    ../../modules/home-manager/waybar.nix
    ../../modules/home-manager/wofi.nix
    inputs.neovim-config.homeManagerModules.default
  ];

  stylix.targets.neovim.enable = lib.mkForce false;

  home.username = "fveracoechea";
  home.homeDirectory = "/home/fveracoechea";

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
