{
  lib,
  config,
  ...
}: {
  options.dotfiles.lazygit.enable = lib.mkEnableOption "lazygit (terminal UI for git)";

  config = lib.mkIf config.dotfiles.lazygit.enable {
    programs.lazygit = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
