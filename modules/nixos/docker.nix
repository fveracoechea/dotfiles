{
  pkgs,
  lib,
  config,
  ...
}: {
  options.dotfiles.docker.enable = lib.mkEnableOption "docker suite (docker daemon, lazydocker, docker-compose)";

  config = lib.mkIf config.dotfiles.docker.enable {
    # Docker daemon
    virtualisation.docker.enable = true;

    # CLI / TUI helpers
    environment.systemPackages = with pkgs; [
      lazydocker
      docker-compose
    ];
  };
}
