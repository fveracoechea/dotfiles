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
        _module.args = {
          dmsThemeSource = inputs.catppuccin-dms;
          dmsSource = inputs.dms;
        };
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
    set -e
    export HOME=/tmp/hyprland-fixture
    export XDG_CONFIG_HOME=${stagedHome}/.config
    export XDG_RUNTIME_DIR="$TMPDIR/runtime"
    mkdir -p "$XDG_RUNTIME_DIR"
    test '${pkgs-stable.hyprland.version}' = '0.55.4'
    test -f "$XDG_CONFIG_HOME/hypr/hyprland.lua"
    if ${pkgs.gnugrep}/bin/grep -q 'hyprland-session.target' "$XDG_CONFIG_HOME/hypr/hyprland.lua"; then
      printf 'Home Manager still controls the Hyprland session target\n' >&2
      exit 1
    fi
    ${pkgs.gnugrep}/bin/grep -q 'uwsm finalize HYPRLAND_INSTANCE_SIGNATURE' "$XDG_CONFIG_HOME/hypr/hyprland.lua" || exit 1
    test -f "$XDG_CONFIG_HOME/systemd/user/dms.service" || exit 1
    ${pkgs.gnugrep}/bin/grep -q '^Requisite=wayland-session@hyprland.desktop.target$' "$XDG_CONFIG_HOME/systemd/user/dms.service" || exit 1
    ${pkgs.gnugrep}/bin/grep -q '^WantedBy=wayland-session@hyprland.desktop.target$' "$XDG_CONFIG_HOME/systemd/user/dms.service" || exit 1
    test ! -e "$XDG_CONFIG_HOME/hypr/entry.lua"
    test ! -e "$XDG_CONFIG_HOME/hypr/hyprland.conf"
    ${pkgs-stable.hyprland}/bin/Hyprland --verify-config -c "$XDG_CONFIG_HOME/hypr/hyprland.lua"
    touch "$out"
  '';
}
