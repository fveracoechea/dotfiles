{
  pkgs,
  desktop,
  ...
}: {
  audio-evaluation = pkgs.writeText "audio-evaluation.json" (builtins.toJSON {
    inherit (desktop.services.pipewire) enable;
    productionTools = desktop.home-manager.users.fveracoechea.dotfiles.pro-audio.enable;
  });
}
