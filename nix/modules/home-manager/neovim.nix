{
  config,
  lib,
  pkgs,
  ...
}: {
  # programs.neovim = {
  #   enable = true;
  #   defaultEditor = true;
  #   viAlias = true;
  #   vimAlias = true;
  #   vimdiffAlias = true;
  # };

  # Enable management of XDG base directories
  xdg.enable = lib.mkDefault true;

  home.packages = [pkgs.neovim];

  xdg.configFile = {
    "lazygit".source = ../../../lazygit;
    "nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nvim";
      recursive = true;
    };
  };
}
