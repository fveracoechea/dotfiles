{...}: {
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    authKeyFile = "/var/lib/tailscale/auth-key";
    extraUpFlags = ["--login-server=https://vpn.veracoechea.com" "--accept-dns=false"];
    extraSetFlags = ["--advertise-routes=10.0.0.0/24" "--accept-dns=false"];
  };
}
