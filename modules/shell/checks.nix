{
  pkgs,
  desktop,
  homelab,
}:
{
  shell-evaluation = pkgs.writeText "shell-evaluation.json" (
    builtins.toJSON {
      desktop = {
        zsh = desktop.home-manager.users.fveracoechea.programs.zsh.enable;
        tmux = desktop.home-manager.users.fveracoechea.programs.tmux.enable;
        systemShell = toString desktop.users.defaultUserShell;
      };
      homelab = {
        systemShell = toString homelab.users.defaultUserShell;
        tmuxShell = homelab.home-manager.users.fveracoechea.programs.tmux.shell;
      };
    }
  );
}
