{
  pkgs,
  lib,
  config,
  ...
}: {
  options.dotfiles.zsh-shell.enable = lib.mkEnableOption "NixOS-side zsh shell integration";

  config = lib.mkIf config.dotfiles.zsh-shell.enable {
    # sets ZSH has default shell
    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;
    environment.pathsToLink = ["/share/zsh"];
    environment.shells = with pkgs; [zsh];
  };
}
