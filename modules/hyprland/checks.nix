{
  pkgs,
  desktop,
  ...
}:
let
  home = desktop.home-manager.users.fveracoechea;
in
{
  hyprland-evaluation = pkgs.writeText "hyprland-evaluation.json" (
    builtins.toJSON {
      inherit (desktop.programs.hyprland) enable withUWSM;
      home = home.wayland.windowManager.hyprland.enable;
      shell = {
        inherit (desktop.programs.dms-shell)
          enable
          package
          quickshell
          systemd
          ;
        settings = builtins.fromJSON (
          builtins.unsafeDiscardStringContext home.xdg.configFile."DankMaterialShell/settings.json".text
        );
        clipboardSettings = builtins.fromJSON home.xdg.configFile."DankMaterialShell/clsettings.json".text;
        session = builtins.fromJSON home.xdg.stateFile."DankMaterialShell/session.json".text;
      };
      hex = home.programs.hex.enable;
    }
  );
}
