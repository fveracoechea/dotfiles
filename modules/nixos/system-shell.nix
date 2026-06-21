{
  pkgs,
  lib,
  config,
  ...
}: {
  # System-level shell: registers zsh as the login shell and ensures it is
  # available in /etc/shells. Complements the home-manager zsh module, which
  # only configures the user's interactive environment (plugins, aliases, etc.)
  # but cannot change the user's login shell.
  options.dotfiles.system-shell.enable = lib.mkEnableOption "NixOS-side shell integration";

  config = lib.mkIf config.dotfiles.system-shell.enable {
    # sets ZSH has default shell
    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;
    environment.pathsToLink = ["/share/zsh"];
    environment.shells = with pkgs; [zsh];
  };
}
