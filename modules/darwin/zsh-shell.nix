{
  pkgs,
  lib,
  config,
  ...
}: {
  options.dotfiles.zsh-shell.enable = lib.mkEnableOption "darwin zsh shell integration";

  config = lib.mkIf config.dotfiles.zsh-shell.enable {
    # Enable ZSH has default shell
    programs.zsh.enable = true;
    environment.pathsToLink = ["/share/zsh"];
    environment.shells = [pkgs.zsh];
    programs.bash.enable = true;
  };
}
