{
  config,
  lib,
  ...
}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraLuaConfig = ''
      require "setup"
    '';
  };

  # Enable management of XDG base directories
  xdg.enable = lib.mkDefault true;

  xdg.configFile = {
    "lazygit".source = ../../../lazygit;
    "nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nvim";
      recursive = true;
    };
  };
}
