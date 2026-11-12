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
      modules = [
        homeModule
        {
          home = {
            username = "audio-fixture";
            homeDirectory = "/home/audio-fixture";
            stateVersion = "24.05";
          };
        }
        settings
      ];
    }).config;
  disabled = home {};
  enabled = home {dotfiles.pro-audio.enable = true;};
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
  systemOn = system {dotfiles.pipewire.enable = true;};
in {
  audio-options = assert lib.assertMsg (
    !builtins.elem pkgs.reaper disabled.home.packages
    && !builtins.elem pkgs.bitwig-studio disabled.home.packages
    && builtins.all (p: builtins.elem p enabled.home.packages) [pkgs.reaper pkgs.bitwig-studio pkgs.wineWow64Packages.stable]
    && !enabled.dotfiles.hyprland.enable
    && !enabled.dotfiles.gaming.enable
    && !systemOff.services.pipewire.enable
    && !systemOff.musnix.enable
    && systemOn.services.pipewire.enable
    && systemOn.services.pipewire.alsa.enable
    && systemOn.services.pipewire.alsa.support32Bit
    && systemOn.services.pipewire.pulse.enable
    && systemOn.services.pipewire.jack.enable
    && systemOn.services.pipewire.wireplumber.enable
    && !systemOn.services.pulseaudio.enable
    && systemOn.security.rtkit.enable
    && systemOn.musnix.enable
    && !systemOn.programs.hyprland.enable
    && !systemOn.programs.steam.enable
  ) "audio: independent Home production tools and System PipeWire";
    pkgs.runCommand "audio-options" {} ''touch "$out"'';
}
