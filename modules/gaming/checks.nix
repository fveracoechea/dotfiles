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
            username = "gaming-fixture";
            homeDirectory = "/home/gaming-fixture";
            stateVersion = "24.05";
          };
        }
        settings
      ];
    }).config;
  disabled = home {};
  enabled = home {dotfiles.gaming.enable = true;};
  withoutHud = home {
    dotfiles = {
      gaming.enable = true;
      mangohud.enable = false;
    };
  };
  hudOnly = home {dotfiles.mangohud.enable = true;};
  streaming = home {dotfiles.sunshine.enable = true;};
  system = settings:
    (nixpkgs.lib.nixosSystem {
      specialArgs.pkgs-latest = pkgs;
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
  systemOn = system {dotfiles.gaming.enable = true;};
  check = name: condition:
    assert lib.assertMsg condition "gaming: ${name}";
      pkgs.runCommand "gaming-${name}" {} ''touch "$out"'';
in {
  gaming-options = check "options" (
    !disabled.programs.mangohud.enable
    && !(disabled.xdg.configFile ? "sunshine/sunshine.conf")
    && enabled.programs.mangohud.enable
    && !withoutHud.programs.mangohud.enable
    && !hudOnly.dotfiles.gaming.enable
    && hudOnly.programs.mangohud.enable
    && !enabled.dotfiles.sunshine.enable
    && !(enabled.xdg.configFile ? "sunshine/sunshine.conf")
    && !streaming.dotfiles.gaming.enable
    && !streaming.programs.mangohud.enable
    && streaming.xdg.configFile ? "sunshine/sunshine.conf"
    && builtins.all (p: builtins.elem p enabled.home.packages) [pkgs.mesa-demos pkgs.protonup-rs pkgs.amdgpu_top pkgs.lutris]
    && !systemOff.programs.steam.enable
    && !systemOff.services.sunshine.enable
    && !systemOff.services.keyd.enable
    && systemOn.programs.steam.enable
    && systemOn.programs.steam.package.version == pkgs.steam.version
    && systemOn.programs.steam.protontricks.package.drvPath == pkgs.protontricks.drvPath
    && map (p: p.drvPath) systemOn.programs.steam.extraCompatPackages == [pkgs.proton-ge-bin.drvPath]
    && systemOn.programs.gamescope.package.drvPath == pkgs.gamescope.drvPath
    && !systemOn.programs.gamescope.capSysNice
    && systemOn.programs.steam.gamescopeSession.args == ["--force-composition" "--disable-layers" "--adaptive-sync" "--rt" "-W 2560" "-H 1440" "-r 120" "-f" "-O HDMI-A-1"]
    && systemOn.services.sunshine.enable
    && !systemOn.services.sunshine.autoStart
    && systemOn.services.sunshine.capSysAdmin
    && systemOn.services.sunshine.openFirewall
    && systemOn.systemd.user.services.sunshine.wantedBy == ["nixos-fake-graphical-session.target"]
    && systemOn.systemd.user.services.sunshine.after == ["graphical-session.target" "nixos-fake-graphical-session.target"]
    && systemOn.systemd.user.services.sunshine.serviceConfig.ExecStartPre == "${pkgs-stable.coreutils}/bin/sleep 10"
    && !systemOn.programs.hyprland.enable
    && !systemOn.dotfiles.pipewire.enable
  );
  gaming-config = pkgs.runCommand "gaming-config" {} ''
    set -eu
    grep -Fx 'capture = kms' ${streaming.xdg.configFile."sunshine/sunshine.conf".source}
    grep -Fx 'encoder = vaapi' ${streaming.xdg.configFile."sunshine/sunshine.conf".source}
    if grep -q output_name ${streaming.xdg.configFile."sunshine/sunshine.conf".source}; then exit 1; fi
    ${pkgs.jq}/bin/jq -e '.apps | length == 2 and all(.[]."prep-cmd"[]; .do == "prepare-steam-stream")' ${streaming.xdg.configFile."sunshine/apps.json".source}
    touch "$out"
  '';
}
