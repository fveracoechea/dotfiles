{
  lib,
  config,
  pkgs-latest,
  ...
}: {
  imports = [../core/spicetify.nix];

  config = lib.mkIf config.dotfiles.spotify.enable {
    # Spotify is an app, so it takes the latest channel. It sits in the system
    # layer only because nix-darwin links `Spotify.app` from
    # `environment.systemPackages` into `/Applications/Nix Apps` for Spotlight
    # and Launchpad, which is a packaging need, not a system concern. The CLI
    # comes from the same channel because spicetify patches the Spotify build.
    # See ADR-0007.
    programs.spicetify = {
      spotifyPackage = pkgs-latest.spotify;
      spicetifyPackage = pkgs-latest.spicetify-cli;
    };
  };
}
