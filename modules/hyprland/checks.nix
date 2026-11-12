{
  pkgs,
  desktop,
  ...
}: let
  home = desktop.home-manager.users.fveracoechea;
in {
  hyprland-evaluation = pkgs.writeText "hyprland-evaluation.json" (builtins.toJSON {
    inherit (desktop.programs.hyprland) enable withUWSM;
    home = home.wayland.windowManager.hyprland.enable;
    shell = home.programs.dank-material-shell.enable;
    hex = home.programs.hex.enable;
  });
}
