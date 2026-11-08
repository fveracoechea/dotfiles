{
  networking = {
    firewall.enable = true;
    nameservers = ["1.1.1.1"];
    hostName = "vps";
    useDHCP = false;
    defaultGateway = {
      address = "168.231.68.254";
      interface = "eth0";
    };
    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "168.231.68.183";
          prefixLength = 24;
        }
      ];
      ipv6.addresses = [
        {
          address = "2a02:4780:2d:c0e8::1";
          prefixLength = 48;
        }
      ];
    };
  };
}
