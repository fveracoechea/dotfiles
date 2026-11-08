{...}: {
  services.adguardhome = {
    enable = true;
    host = "127.0.0.1";
    port = 8082;
    mutableSettings = false;
    settings = {
      users = [
        {
          name = "admin";
          password = "$2b$12$jeSGNoPYjq6WpVsQ6SMU3eYpOR7XtwqlUOZS/nns4/T.nfDXxl5Jm";
        }
      ];
      dns = {
        bind_hosts = ["10.0.0.2"];
        port = 53;
        upstream_dns = ["1.1.1.1"];
        fallback_dns = ["9.9.9.9"];
        bootstrap_dns = ["1.1.1.1" "9.9.9.9"];
        cache_enabled = true;
        cache_size = 52428800;
        cache_optimistic = true;
        upstream_timeout = "3s";
        enable_dnssec = false;
      };
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        parental_enabled = false;
        safe_search.enabled = false;
        rewrites = [
          {
            domain = "photos.veracoechea.com";
            answer = "10.0.0.2";
            enabled = true;
          }
        ];
      };
      filters =
        map (url: {
          enabled = true;
          inherit url;
        }) [
          "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"
          "https://adguardteam.github.io/HostlistsRegistry/assets/filter_7.txt"
          "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt"
          "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt"
          "https://adguardteam.github.io/HostlistsRegistry/assets/filter_44.txt"
          "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/nsfw.txt"
        ];
    };
  };

  services.caddy.virtualHosts."ad-blocker.veracoechea.com".extraConfig = ''
    tls /var/lib/acme/veracoechea.com/fullchain.pem /var/lib/acme/veracoechea.com/key.pem
    reverse_proxy 127.0.0.1:8082
  '';

  networking.firewall.interfaces.enp8s0 = {
    allowedUDPPorts = [53];
    allowedTCPPorts = [53];
  };
}
