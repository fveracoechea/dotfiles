{
  pkgs,
  lib,
  config,
  ...
}: {
  # System-level shell: registers zsh as an accepted shell and enables bash.
  # Complements the home-manager zsh module, which only configures the user's
  # interactive environment (plugins, aliases, etc.) but cannot change the
  # user's login shell.
  options.dotfiles.system-shell.enable = lib.mkEnableOption "darwin shell integration";

  config = lib.mkIf config.dotfiles.system-shell.enable {
    # Enable ZSH has default shell
    programs.zsh.enable = true;
    environment.pathsToLink = ["/share/zsh"];
    environment.shells = [pkgs.zsh];
    programs.bash.enable = true;
  };
}
