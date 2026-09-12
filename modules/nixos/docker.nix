{
  lib,
  config,
  ...
}: {
  options.dotfiles.docker.enable = lib.mkEnableOption "Docker daemon";

  config = lib.mkIf config.dotfiles.docker.enable {
    virtualisation.docker.enable = true;
  };
}
