{
  pkgs,
  desktop,
  ...
}: {
  networking-evaluation = pkgs.writeText "networking-evaluation.json" (builtins.toJSON {
    inherit (desktop.networking) hostName;
    firewall = desktop.networking.firewall.enable;
    iwd = desktop.networking.wireless.iwd.enable;
  });
}
