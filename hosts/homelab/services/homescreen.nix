{ dotfilesPkgs, lib, ... }:
let
  port = 3002;
in
{
  systemd.tmpfiles.rules = [
    "d /var/lib/homescreen 0700 root root -"
  ];

  systemd.services.homescreen = {
    description = "Homescreen media API";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    environment = {
      MEDIA_HOST = "127.0.0.1";
      MEDIA_PORT = toString port;
    };
    serviceConfig = {
      ExecStart = lib.getExe dotfilesPkgs.homescreen-server;
      EnvironmentFile = "/var/lib/homescreen/homescreen.env";
      DynamicUser = true;
      Restart = "on-failure";
      RestartSec = 5;
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      RestrictSUIDSGID = true;
      UMask = "0077";
    };
  };

  services.caddy.virtualHosts."homescreen.veracoechea.com".extraConfig = ''
    tls /var/lib/acme/veracoechea.com/fullchain.pem /var/lib/acme/veracoechea.com/key.pem
    @lan remote_ip 10.0.0.0/24
    handle @lan {
      reverse_proxy 127.0.0.1:${toString port}
    }
    handle {
      respond 403
    }
  '';
}
