{...}: {
  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    configurePostgres = true;
    environmentFile = "/var/lib/vaultwarden/vaultwarden.env";
    config = {
      DOMAIN = "https://warden.veracoechea.com";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";
      SIGNUPS_ALLOWED = false;
    };
  };

  services.caddy.virtualHosts."warden.veracoechea.com".extraConfig = ''
    tls /var/lib/acme/veracoechea.com/fullchain.pem /var/lib/acme/veracoechea.com/key.pem
    reverse_proxy 127.0.0.1:8222
  '';
}
