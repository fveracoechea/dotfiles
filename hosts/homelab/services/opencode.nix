{config, lib, ...}: {
  dotfiles.coding-agents.web.enable = true;
  services.caddy.virtualHosts."opencode.veracoechea.com" = lib.mkIf config.dotfiles.coding-agents.web.enable {
    extraConfig = ''
      tls /var/lib/acme/veracoechea.com/fullchain.pem /var/lib/acme/veracoechea.com/key.pem
      @tailnet remote_ip 100.64.0.0/10
      handle @tailnet {
        reverse_proxy 127.0.0.1:${toString config.dotfiles.coding-agents.web.port}
      }
      handle {
        respond 403
      }
    '';
  };
}
