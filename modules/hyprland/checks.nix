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
in {
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
