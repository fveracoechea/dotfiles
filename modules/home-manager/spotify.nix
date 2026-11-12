{
  lib,
  config,
  ...
}:
{
  imports = [ ../core/spicetify.nix ];

  config = lib.mkIf config.dotfiles.spotify.enable {
    programs.cava.enable = true;
  };
}
