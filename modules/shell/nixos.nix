{
  pkgs,
  lib,
  config,
  ...
}: {
  options.dotfiles.system-shell.enable = lib.mkEnableOption "NixOS-side shell integration";

  config = lib.mkIf config.dotfiles.system-shell.enable {
    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;
    environment.pathsToLink = ["/share/zsh"];
    environment.shells = with pkgs; [zsh];
  };
}
