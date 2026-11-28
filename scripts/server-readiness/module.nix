{ host, source }:
{
  config,
  lib,
  pkgs,
  options,
  ...
}:
{
  environment.etc."dotfiles/server-manifest.json".source = pkgs.writeText "server-manifest.json" (
    builtins.toJSON (
      import ./manifest.nix {
        inherit
          lib
          config
          host
          source
          pkgs
          options
          ;
      }
    )
  );
}
