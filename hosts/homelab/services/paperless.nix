{ ... }: {
  services.paperless = {
    enable = true;
    address = "127.0.0.1";
    passwordFile = "/var/lib/paperless/admin-password";
    database.createLocally = true;
    settings = {
      PAPERLESS_ADMIN_USER = "fveracoechea";
      PAPERLESS_URL = "https://docs.veracoechea.com";
      PAPERLESS_OCR_LANGUAGE = "eng";
      PAPERLESS_CONSUMER_IGNORE_PATTERN = [
        ".DS_STORE/*"
        "desktop.ini"
      ];
    };
  };

  services.caddy.virtualHosts."docs.veracoechea.com".extraConfig = ''
    tls /var/lib/acme/veracoechea.com/fullchain.pem /var/lib/acme/veracoechea.com/key.pem
    reverse_proxy 127.0.0.1:28981
  '';
}
