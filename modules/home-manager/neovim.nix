{
  lib,
  config,
  ...
}: {
  options.dotfiles.neovim.enable = lib.mkEnableOption "shared Neovim configuration";

  config = lib.mkIf config.dotfiles.neovim.enable {
    programs.neovim-config.enable = true;
  };
}
