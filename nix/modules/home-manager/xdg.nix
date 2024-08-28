{config, ...}: {
  # Enable management of XDG base directories
  xdg.enable = true;

  xdg.configFile = {
    "lazygit".source = ../../../lazygit;
    "nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nvim";
      recursive = true;
    };
  };
}
