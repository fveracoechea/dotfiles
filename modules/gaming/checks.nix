{
  pkgs,
  desktop,
  ...
}: {
  gaming-evaluation = pkgs.writeText "gaming-evaluation.json" (builtins.toJSON {
    steam = desktop.programs.steam.enable;
    sunshine = desktop.services.sunshine.enable;
    mangohud = desktop.home-manager.users.fveracoechea.programs.mangohud.enable;
  });
}
