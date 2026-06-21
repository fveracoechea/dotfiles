{
  lib,
  config,
  ...
}: {
  options.dotfiles.networking.enable = lib.mkEnableOption "networking stack (hostname, firewall, iwd)";

  config = lib.mkIf config.dotfiles.networking.enable {
    networking = {
      hostName = "nixos";

      interfaces."eno1".wakeOnLan.enable = true;

      firewall.enable = true;

      # wireless.enable = true;
      wireless.iwd.enable = true;
      networkmanager.wifi.backend = "iwd";

      # wg-quick.interfaces.payintel-aws.configFile = "/etc/nixos/wireguard/payintel-aws.conf";
    };
  };
}
