{ ... }: {
  services.immich = {
    enable = true;
    host = "127.0.0.1";
    openFirewall = false;
  };
  services.redis.servers.immich.logLevel = "warning";

  services.caddy.virtualHosts."photos.veracoechea.com".extraConfig = ''
    tls /var/lib/acme/veracoechea.com/fullchain.pem /var/lib/acme/veracoechea.com/key.pem
    reverse_proxy 127.0.0.1:2283
  '';
}
