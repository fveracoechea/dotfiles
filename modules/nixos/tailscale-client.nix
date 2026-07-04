{
  lib,
  config,
  ...
}: {
  options.dotfiles.tailscale-client.enable = lib.mkEnableOption "Enable Tailscale client";

  config = lib.mkIf config.dotfiles.tailscale-client.enable {
    # sudo tailscale up --login-server=https://vpn.veracoechea.com
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      extraUpFlags = ["--login-server=https://vpn.veracoechea.com"];
    };
  };
}
