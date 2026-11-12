{
  pkgs,
  desktop,
  homelab,
}:
let
  home = desktop.home-manager.users.fveracoechea;
  serverHome = homelab.home-manager.users.fveracoechea;
in
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
          inherit (homelab.dotfiles.coding-agents.web) enable port environmentFile;
          inherit (homelab.systemd.services.opencode-web.serviceConfig) User Group;
        };
      };
    }
  );
}
