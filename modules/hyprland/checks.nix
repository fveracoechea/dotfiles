{
  lib,
  pkgs,
  pkgs-stable,
  home-manager,
  homeModule,
  nixpkgs,
  nixosModule,
}: let
  home = settings:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {inherit pkgs-stable;};
      modules = [
        homeModule
        {
          home = {
            username = "hyprland-fixture";
            homeDirectory = "/home/hyprland-fixture";
            stateVersion = "24.05";
          };
        }
        settings
      ];
    }).config;
  disabled = home {};
  enabled = home {dotfiles.hyprland.enable = true;};
  hexOnly = home {dotfiles.hex.enable = true;};
  integrated = home {
    dotfiles = {
      hyprland.enable = true;
      hex.enable = true;
    };
  };
  overridden = home {
    dotfiles = {
      hyprland.enable = true;
      hex.enable = true;
    };
    programs.hex.systemdTarget = "custom-session.target";
  };
  system = settings:
    (nixpkgs.lib.nixosSystem {
      modules = [
        nixosModule
        {
          nixpkgs.pkgs = pkgs-stable;
          system.stateVersion = "24.05";
        }
        settings
      ];
    }).config;
  systemOff = system {};
  systemOn = system {dotfiles.hyprland.enable = true;};
  target = "wayland-session@hyprland.desktop.target";
  check = name: condition:
    assert lib.assertMsg condition "hyprland: ${name}";
      pkgs.runCommand "hyprland-${name}" {} ''touch "$out"'';
  configHome = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = {inherit pkgs-stable;};
    modules = [
      homeModule
      {
        home = {
          username = "hyprland-fixture";
          homeDirectory = "/tmp/hyprland-fixture";
          stateVersion = "25.05";
        };
        dotfiles.hyprland.enable = true;
      }
    ];
  };
  stagedHome = pkgs.linkFarm "hyprland-config" (lib.mapAttrsToList (_: file: {
    name = file.target;
    path = file.source;
  }) (lib.filterAttrs (_: file: file.enable) configHome.config.xdg.configFile));
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
  hyprland-options = check "options" (
    !disabled.wayland.windowManager.hyprland.enable
    && !disabled.services.hypridle.enable
    && !disabled.services.hyprpaper.enable
    && !disabled.programs.dank-material-shell.enable
    && !disabled.programs.hex.enable
    && !(disabled.xdg.configFile ? "dotfiles/hyprland.stamp")
    && enabled.wayland.windowManager.hyprland.enable
    && enabled.wayland.windowManager.hyprland.package == null
    && enabled.wayland.windowManager.hyprland.portalPackage == null
    && !enabled.wayland.windowManager.hyprland.systemd.enable
    && enabled.services.hypridle.package.drvPath == pkgs-stable.hypridle.drvPath
    && enabled.services.hyprpaper.package.drvPath == pkgs-stable.hyprpaper.drvPath
    && enabled.programs.dank-material-shell.systemd.target == target
    && !enabled.programs.hex.enable
    && !(enabled.systemd.user.services ? hex)
    && !systemOff.programs.hyprland.enable
    && systemOn.programs.hyprland.enable
    && systemOn.programs.hyprland.withUWSM
    && systemOn.programs.hyprland.package.drvPath == pkgs-stable.hyprland.drvPath
    && systemOn.hardware.graphics.enable32Bit
    && systemOn.hardware.bluetooth.powerOnBoot
  );
  hyprland-hex = check "hex" (
    !hexOnly.wayland.windowManager.hyprland.enable
    && hexOnly.programs.hex.systemdTarget == "graphical-session.target"
    && integrated.programs.hex.systemdTarget == target
    && integrated.programs.hex.autostart
    && integrated.systemd.user.services.hex.Unit.After == [target]
    && integrated.systemd.user.services.hex.Unit.PartOf == [target]
    && integrated.systemd.user.services.hex.Install.WantedBy == [target]
    && overridden.programs.hex.systemdTarget == "custom-session.target"
    && overridden.systemd.user.services.hex.Install.WantedBy == ["custom-session.target"]
  );
}
