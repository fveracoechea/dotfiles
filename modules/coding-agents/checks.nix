{
  pkgs,
  desktop,
  homelab,
}:
let
  home = desktop.home-manager.users.fveracoechea;
  serverHome = homelab.home-manager.users.fveracoechea;
  sharedService = serverHome.systemd.user.services.opencode;
  browse = serverHome.programs.opencode.settings.mcp.servers.browse;
in
assert !homelab.dotfiles.coding-agents.web.enable;
assert !(homelab.systemd.services ? opencode-web);
assert homelab.users.users.fveracoechea.linger;
assert sharedService.Install.WantedBy == [ "default.target" ];
assert sharedService.Service.UMask == "0077";
assert browse.type == "local";
assert browse.environment.OPENCODE_BROWSER_AUTO_UPDATE == "off";
assert browse.environment.OPENCODE_BROWSER_PORT == "19988";
assert
  (builtins.fromJSON serverHome.xdg.configFile."browse/config.json".text).hostname == "0.0.0.0";
assert builtins.elem 19988 homelab.networking.firewall.interfaces.tailscale0.allowedTCPPorts;
assert !(builtins.elem 19988 homelab.networking.firewall.allowedTCPPorts);
assert !(home.programs.opencode.settings.mcp.servers ? browse);
{
  coding-agents-evaluation = pkgs.writeText "coding-agents-evaluation.json" (
    builtins.toJSON {
      desktop = {
        inherit (home.programs.opencode)
          enable
          package
          settings
          cli
          validateFiles
          ;
        herdr = home.programs.herdr.settings;
      };
      homelab = {
        inherit (serverHome.programs.opencode)
          enable
          package
          settings
          cli
          validateFiles
          ;
        herdr = serverHome.programs.herdr.settings;
        web = {
          dedicated = homelab.dotfiles.coding-agents.web.enable;
          service = sharedService;
          linger = homelab.users.users.fveracoechea.linger;
          proxy = homelab.services.caddy.virtualHosts."opencode.veracoechea.com".extraConfig;
        };
      };
    }
  );
}
