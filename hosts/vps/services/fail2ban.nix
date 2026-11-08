{...}: {
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "1week";
    };
    jails = {
      sshd = {
        enabled = true;
        settings = {
          mode = "aggressive";
          findtime = "10m";
        };
      };
      headscale-api = {
        enabled = true;
        settings = {
          port = "443";
          backend = "auto";
          filter = "headscale-api";
          logpath = "/var/log/caddy/access-vpn.veracoechea.com.log";
          maxretry = 5;
          findtime = "10m";
          bantime = "1h";
        };
      };
    };
  };
  environment.etc."fail2ban/filter.d/headscale-api.conf".text = ''
    [Definition]
    failregex = ^.*"remote_ip"\s*:\s*"<HOST>".*"status"\s*:\s*(?:401|403)(?:,|}).*$
    ignoreregex =
  '';
}
