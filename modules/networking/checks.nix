{
  lib,
  pkgs,
  nixpkgs,
  nixosModule,
}: let
  fixture = settings: (nixpkgs.lib.nixosSystem {
    modules = [
      nixosModule
      {
        nixpkgs.hostPlatform = pkgs.stdenv.hostPlatform.system;
        system.stateVersion = "24.05";
      }
      settings
    ];
  }).config;
  disabled = fixture {};
  enabled = fixture {dotfiles.networking.enable = true;};
  machine = fixture {
    dotfiles.networking.enable = true;
    networking = {
      hostName = "fixture-host";
      interfaces.fixture0.wakeOnLan.enable = true;
    };
  };
  check = name: condition:
    assert lib.assertMsg condition "networking: ${name}";
      pkgs.runCommand "networking-${name}" {} ''touch "$out"'';
in {
  networking-options = check "options" (
    !disabled.networking.wireless.iwd.enable
    && enabled.networking.wireless.iwd.enable
    && enabled.networking.firewall.enable
    && enabled.networking.networkmanager.wifi.backend == "iwd"
    && enabled.networking.hostName == disabled.networking.hostName
    && enabled.networking.interfaces == {}
    && machine.networking.hostName == "fixture-host"
    && builtins.attrNames machine.networking.interfaces == ["fixture0"]
    && machine.networking.interfaces.fixture0.wakeOnLan.enable
  );
}
