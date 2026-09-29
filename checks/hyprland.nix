{
  lib,
  inputs,
  pkgs,
  pkgs-stable,
}: let
  home = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = {inherit pkgs-stable;};
    modules = [
      inputs.dms.homeModules.dank-material-shell
      ../modules/home-manager/hyprland
      ../modules/core/palette.nix
      {
        _module.args.dmsThemeSource = inputs.catppuccin-dms;
        home = {
          username = "hyprland-fixture";
          homeDirectory = "/tmp/hyprland-fixture";
          stateVersion = "25.05";
        };
        dotfiles.hyprland.enable = true;
      }
    ];
  };
  files = home.config.xdg.configFile;
  stagedHome = pkgs.linkFarm "hyprland-config" (lib.mapAttrsToList (_: file: {
    name = file.target;
    path = file.source;
  }) (lib.filterAttrs (_: file: file.enable) files));
in {
  hyprland-config = pkgs.runCommand "hyprland-config" {} ''
    export HOME=/tmp/hyprland-fixture
    export XDG_CONFIG_HOME=${stagedHome}/.config
    export XDG_RUNTIME_DIR="$TMPDIR/runtime"
    mkdir -p "$XDG_RUNTIME_DIR"
    test '${pkgs-stable.hyprland.version}' = '0.55.4'
    test -f "$XDG_CONFIG_HOME/hypr/hyprland.lua"
    test ! -e "$XDG_CONFIG_HOME/hypr/entry.lua"
    test ! -e "$XDG_CONFIG_HOME/hypr/hyprland.conf"
    ${pkgs-stable.hyprland}/bin/Hyprland --verify-config -c "$XDG_CONFIG_HOME/hypr/hyprland.lua"
    touch "$out"
  '';
}
