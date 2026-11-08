{
  lib,
  inputs,
  hosts,
  pkgs,
}: let
  baseline = builtins.fromJSON (builtins.readFile ./server-baseline.json);
  plain = value: builtins.unsafeDiscardStringContext (toString value);
  packageIdentity = package: {
    name = package.pname or package.name;
    version = package.version;
    path = plain package;
    derivation = plain package.drvPath;
  };

  # The deployed System identity covers transitive runtimes, generated files,
  # permissions, networking, and Home Manager, not just top-level versions.
  preserved = candidates: {
    homelab = let
      host = candidates.homelab;
      originalImage = host.extendModules {
        modules = [
          ({lib, ...}: {
            virtualisation.oci-containers.containers.paperless-gpt.image =
              lib.mkOverride 0 baseline.paperlessGpt.originalReference;
          })
        ];
      };
    in
      host.config.virtualisation.oci-containers.containers.paperless-gpt.image
      == baseline.paperlessGpt.image
      && plain originalImage.config.system.build.toplevel
      == baseline.hosts.homelab.systemPath
      && host.config.system.stateVersion == baseline.hosts.homelab.systemStateVersion
      && host.config.home-manager.users.fveracoechea.home.stateVersion == baseline.hosts.homelab.homeStateVersion;
    vps = let
      host = candidates.vps;
      originalHostname = host.extendModules {
        modules = [
          ({lib, ...}: {
            networking.hostName = lib.mkOverride 0 baseline.hosts.vps.hostname;
          })
        ];
      };
    in
      host.config.networking.hostName
      == "vps"
      && plain originalHostname.config.system.build.toplevel
      == baseline.hosts.vps.systemPath
      && host.config.system.stateVersion == baseline.hosts.vps.systemStateVersion;
  };
  accepted = candidates: builtins.all (value: value) (builtins.attrValues (preserved candidates));

  olderService = hosts.vps.extendModules {
    modules = [
      ({lib, ...}: {
        services.headscale.package = lib.mkForce (
          # Evaluation-only version mutation. This fixture is never built.
          hosts.vps.config.services.headscale.package.overrideAttrs {
            version = "0.28.0";
            __intentionallyOverridingVersion = true;
          }
        );
      })
    ];
  };
  changedDatabase = hosts.homelab.extendModules {
    modules = [
      ({
        lib,
        pkgs,
        ...
      }: {services.postgresql.package = lib.mkForce pkgs.postgresql_16;})
    ];
  };
  changedImage = hosts.homelab.extendModules {
    modules = [
      ({lib, ...}: {
        virtualisation.oci-containers.containers.paperless-gpt.image = lib.mkForce "ghcr.io/icereed/paperless-gpt:latest";
      })
    ];
  };
  unexpectedHostname = hosts.vps.extendModules {
    modules = [({lib, ...}: {networking.hostName = lib.mkForce "unexpected-vps";})];
  };

  manifests =
    lib.mapAttrs (_: host: let
      c = host.config;
      serviceNames = [
        "adguardhome"
        "caddy"
        "fail2ban"
        "headplane"
        "headscale"
        "immich"
        "ollama"
        "paperless"
        "postgresql"
        "tailscale"
        "vaultwarden"
        "zwave-js"
      ];
      enabledServices = builtins.filter (name: c.services.${name}.enable) serviceNames;
      hasHome = c ? home-manager && c.home-manager.users ? fveracoechea;
    in {
      hostname = c.networking.hostName;
      systemPath = plain c.system.build.toplevel;
      systemDerivation = plain c.system.build.toplevel.drvPath;
      systemStateVersion = c.system.stateVersion;
      homeStateVersion =
        if hasHome
        then c.home-manager.users.fveracoechea.home.stateVersion
        else null;
      packages =
        builtins.listToAttrs (map (name: {
            inherit name;
            value = packageIdentity c.services.${name}.package;
          })
          enabledServices)
        // lib.optionalAttrs c.services.immich.enable {
          immich-machine-learning = packageIdentity c.services.immich.package.machine-learning;
          redis = packageIdentity c.services.redis.package;
        }
        // lib.optionalAttrs c.services.postgresql.enable {
          postgresql-with-extensions = packageIdentity c.services.postgresql.finalPackage;
        }
        // lib.optionalAttrs c.services.home-assistant.enable {
          home-assistant = packageIdentity c.services.home-assistant.finalPackage;
        }
        // lib.optionalAttrs c.services.vaultwarden.enable {
          vaultwarden = packageIdentity (c.services.vaultwarden.package.override {
            inherit (c.services.vaultwarden) dbBackend;
          });
          vaultwarden-webvault = packageIdentity c.services.vaultwarden.webVaultPackage;
        }
        // lib.optionalAttrs c.virtualisation.podman.enable {
          podman = packageIdentity c.virtualisation.podman.package;
        };
      postgresqlExtensions =
        lib.optionals c.services.postgresql.enable
        (map packageIdentity (c.services.postgresql.extensions c.services.postgresql.package.pkgs));
      containers =
        lib.mapAttrs (_: container: {
          inherit (container) image environment environmentFiles volumes extraOptions;
        })
        c.virtualisation.oci-containers.containers;
      firewall = {
        inherit (c.networking.firewall) enable allowedTCPPorts allowedUDPPorts interfaces trustedInterfaces;
      };
      networking = {
        inherit (c.networking) nameservers defaultGateway useDHCP;
        interfaces =
          lib.mapAttrs (_: interface: {
            inherit (interface) useDHCP;
            ipv4 = interface.ipv4.addresses;
            ipv6 = interface.ipv6.addresses;
          })
          c.networking.interfaces;
      };
      serviceUnits =
        lib.mapAttrs (_: unit: {
          execStart = plain (unit.serviceConfig.ExecStart or "");
          stateDirectory = unit.serviceConfig.StateDirectory or null;
        }) (lib.filterAttrs (name: _:
          builtins.elem name [
            "immich-server"
            "immich-machine-learning"
            "paperless-web"
            "paperless-task-queue"
            "home-assistant"
            "ollama"
            "postgresql"
            "redis-immich"
            "vaultwarden"
            "adguardhome"
            "caddy"
            "tailscaled"
            "zwave-js"
            "headscale"
            "headplane"
            "fail2ban"
          ])
        c.systemd.services);
      reverseProxy = lib.mapAttrs (_: vhost: vhost.extraConfig) c.services.caddy.virtualHosts;
      tailnet = lib.optionalAttrs c.services.tailscale.enable {
        inherit (c.services.tailscale) authKeyFile extraUpFlags extraSetFlags useRoutingFeatures;
      };
      desktopServices = {
        hyprland = c.programs.hyprland.enable;
        steam = c.programs.steam.enable;
        pipewire = c.services.pipewire.enable;
        displayManager = c.services.displayManager.ly.enable;
      };
    })
    hosts;

  isolation = let
    serverHasNoDesktop = name: !(builtins.any (value: value) (builtins.attrValues manifests.${name}.desktopServices));
    desktop = hosts.nixos-desktop.config;
  in
    serverHasNoDesktop "homelab"
    && serverHasNoDesktop "vps"
    && !(builtins.any (name: desktop.services.${name}.enable) [
      "immich"
      "paperless"
      "home-assistant"
      "headscale"
      "headplane"
      "adguardhome"
      "vaultwarden"
      "ollama"
    ])
    && manifests.nixos-desktop.systemStateVersion == "24.05"
    && manifests.nixos-desktop.homeStateVersion == "24.05"
    && desktop.home-manager.users.fveracoechea.programs.ssh.settings ? vps
    && !(desktop.home-manager.users.fveracoechea.programs.ssh.settings ? hostinger);

  preservation = preserved hosts;
  baselineDetailsMatch = builtins.all (name: let
    expected = baseline.hosts.${name};
    actual = manifests.${name};
  in
    actual.systemStateVersion
    == expected.systemStateVersion
    && actual.homeStateVersion == expected.homeStateVersion
    && builtins.all (service: actual.packages.${service}.version == expected.serviceVersions.${service})
    (builtins.attrNames expected.serviceVersions)) ["homelab" "vps"];
  negativeCases = {
    older-service =
      lib.versionOlder olderService.config.services.headscale.package.version
      hosts.vps.config.services.headscale.package.version
      && !(accepted (hosts // {vps = olderService;}));
    changed-database-major = !(accepted (hosts // {homelab = changedDatabase;}));
    unapproved-image = !(accepted (hosts // {homelab = changedImage;}));
    unexpected-vps-hostname = !(accepted (hosts // {vps = unexpectedHostname;}));
  };
in {
  inherit manifests preservation negativeCases;
  check = assert lib.assertMsg (accepted hosts) "Server configuration differs from the verified deployed baseline. See lib.serverPreservation and ADR-0008.";
  assert lib.assertMsg isolation "Host isolation or desktop State Versions changed.";
  assert lib.assertMsg baselineDetailsMatch "Recorded server versions or State Versions differ from evaluation.";
  assert inputs.nixpkgs-servers.rev == baseline.nixpkgsRevision;
  assert inputs.server-home-manager.rev == baseline.homeManagerRevision;
  assert inputs.server-dotfiles-compat.rev == baseline.sharedModulesRevision;
  assert inputs.server-disko.rev == baseline.diskoRevision;
  assert lib.assertMsg (builtins.all (value: value) (builtins.attrValues negativeCases)) "A preservation negative case was accepted.";
    pkgs.runCommand "host-preservation" {} ''
      touch "$out"
    '';
}
