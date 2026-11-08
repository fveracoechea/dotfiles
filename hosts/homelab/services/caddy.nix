{config, ...}: {
  security.acme = {
    acceptTerms = true;
    defaults.email = "fveracoechea@veracoechea.com";
    certs."veracoechea.com" = {
      domain = "veracoechea.com";
      extraDomainNames = ["*.veracoechea.com"];
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = true;
      group = config.services.caddy.group;
      environmentFile = "/var/lib/caddy/caddy.env";
      reloadServices = ["caddy.service"];
    };
  };

  services.caddy = {
    enable = true;
    globalConfig = ''
      auto_https off
    '';
    virtualHosts = {
      "http://veracoechea.com".extraConfig = ''
        redir https://{host}{uri}
      '';
      "http://*.veracoechea.com".extraConfig = ''
        redir https://{host}{uri}
      '';
    };
  };

  networking.firewall.interfaces.enp8s0.allowedTCPPorts = [80 443];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [80 443];
}
