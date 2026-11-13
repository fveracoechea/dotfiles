{ lib, ... }:
let
  port = 49374;
in
{
  dotfiles.coding-agents.web.enable = false;
  users.users.fveracoechea.linger = true;

  home-manager.users.fveracoechea = { config, ... }: {
    systemd.user.startServices = "sd-switch";
    systemd.user.services.opencode = {
      Unit.Description = "Shared OpenCode server for terminal and web clients";
      Service = {
        ExecStartPre = "${lib.getExe config.programs.opencode.package} service stop";
        ExecStart = "${lib.getExe config.programs.opencode.package} serve --service --hostname 127.0.0.1 --port ${toString port}";
        WorkingDirectory = config.home.homeDirectory;
        Environment = "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin";
        UMask = "0077";
        Restart = "always";
        RestartSec = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };

  services.caddy.virtualHosts."opencode.veracoechea.com".extraConfig = ''
    tls /var/lib/acme/veracoechea.com/fullchain.pem /var/lib/acme/veracoechea.com/key.pem
    @tailnet remote_ip 100.64.0.0/10
    handle @tailnet {
      reverse_proxy 127.0.0.1:${toString port}
    }
    handle {
      respond 403
    }
  '';
}
