{ lib, ... }:
let
  port = 19988;
  environment = {
    OPENCODE_BROWSER_AUTO_UPDATE = "off";
    OPENCODE_BROWSER_PORT = toString port;
  };
in
{
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];

  home-manager.users.fveracoechea = { dotfilesPkgs, ... }: {
    home.packages = [ dotfilesPkgs.browse ];
    home.sessionVariables = environment;

    xdg.configFile."browse/config.json".text = builtins.toJSON {
      hostname = "0.0.0.0";
    };

    programs.opencode.settings.mcp.servers.browse = {
      type = "local";
      command = [
        (lib.getExe dotfilesPkgs.browse)
        "mcp"
      ];
      inherit environment;
    };
  };
}
