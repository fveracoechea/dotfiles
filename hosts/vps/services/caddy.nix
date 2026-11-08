{config, ...}: {
  security.acme = {
    acceptTerms = true;
    defaults.email = "fveracoechea@veracoechea.com";
    certs."vpn.veracoechea.com" = {
      domain = "vpn.veracoechea.com";
      extraDomainNames = ["network.veracoechea.com"];
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
  };
  networking.firewall.allowedTCPPorts = [80 443];
}
