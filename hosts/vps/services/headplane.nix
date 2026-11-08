{
  config,
  lib,
  pkgs,
  ...
}: let
  format = pkgs.formats.yaml {};
  headscaleConfig = format.generate "headscale.yml" (
    lib.recursiveUpdate config.services.headscale.settings {
      tls_cert_path = "/dev/null";
      tls_key_path = "/dev/null";
      policy.path = "/dev/null";
    }
  );
in {
  services.headplane = {
    enable = true;
    settings = {
      server = {
        host = "127.0.0.1";
        port = 3000;
        base_url = "https://network.veracoechea.com";
        cookie_secret_path = "/var/lib/headplane/cookie-secret";
      };
      headscale = {
        url = "https://vpn.veracoechea.com";
        config_path = "${headscaleConfig}";
      };
      integration.proc.enabled = true;
    };
  };

  services.caddy.virtualHosts."network.veracoechea.com".extraConfig = ''
    tls /var/lib/acme/vpn.veracoechea.com/fullchain.pem /var/lib/acme/vpn.veracoechea.com/key.pem
    @tailnet remote_ip 100.64.0.0/10
    handle @tailnet {
      reverse_proxy 127.0.0.1:3000
    }
    handle {
      respond 403
    }
  '';
}
