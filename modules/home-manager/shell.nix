{
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./zsh.nix
    ./tmux
    ./bat.nix
    ./btop.nix
    ./yazi.nix
    ./git.nix
  ];

  options.dotfiles.shell.enable = lib.mkEnableOption "shell suite (zsh, tmux, bat, btop, yazi, git, lazydocker)";

  config = lib.mkIf config.dotfiles.shell.enable {
    home.packages = with pkgs; [
      watchman
      wireguard-tools
      agent-browser
    ];

    dotfiles.zsh.enable = lib.mkDefault true;
    dotfiles.tmux.enable = lib.mkDefault true;
    dotfiles.bat.enable = lib.mkDefault true;
    dotfiles.btop.enable = lib.mkDefault true;
    dotfiles.yazi.enable = lib.mkDefault true;
    dotfiles.git.enable = lib.mkDefault true;
  };
}
