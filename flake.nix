{
  description = "Linux dotfiles and NixOS configuration";

  inputs = {
    # Latest channel: apps, CLI, and tooling. `nixpkgs-unstable`, not
    # `nixos-unstable`: this input no longer builds a NixOS system, so the
    # NixOS VM integration tests that gate `nixos-unstable` validate nothing
    # it provides. See ADR-0007.
    nixpkgs-latest.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Release channel: system packages and services.
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

    # Deployed server graph. Remove only after the ADR-0008 migration gates pass.
    nixpkgs-servers.url = "github:nixos/nixpkgs/2fcb964de67fcf60b43471c55d5d99e61a9ccb5a";
    server-disko.url = "github:nix-community/disko/ff8702b4de27f72b4c78573dfb89ec74e36abdf1";
    server-disko.inputs.nixpkgs.follows = "nixpkgs-servers";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs-stable";
    server-dotfiles-compat.url = "github:fveracoechea/dotfiles/a4ede6eddbb6f3bc3b8c98cff0d86c99661f0f46";
    server-dotfiles-compat.inputs.nixpkgs.follows = "nixpkgs-servers";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-latest";

    neovim.url = "github:fveracoechea/neovim/01b3c02dc8891ea60b4a552f45bf6fa2b3d95da4";
    neovim.inputs.nixpkgs.follows = "nixpkgs-latest";
    neovim.inputs.home-manager.follows = "home-manager";

    catppuccin-dms.url = "github:catppuccin/dankmaterialshell";
    catppuccin-dms.flake = false;

    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs-stable";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs-latest";

    tmux-powerkit.url = "github:fabioluciano/tmux-powerkit";
    tmux-powerkit.inputs.nixpkgs.follows = "nixpkgs-latest";

    hunk.url = "github:modem-dev/hunk";
    hunk.inputs.nixpkgs.follows = "nixpkgs-latest";

    herdr.url = "github:herdrdev/herdr";
    herdr.inputs.nixpkgs.follows = "nixpkgs-latest";

    operator.url = "github:fveracoechea/operator/v2.3.2";
    operator.inputs.nixpkgs.follows = "nixpkgs-latest";

    # Agent prompts can advance without upgrading the Operator CLI or device state.
    operator-agents = {
      url = "github:fveracoechea/operator/v2.3.2";
      flake = false;
    };

    hex.url = "github:anomalyco/hex/dev";
    hex.inputs.nixpkgs.follows = "nixpkgs-latest";
    hex.inputs.home-manager.follows = "home-manager";

    dev-manager-desktop.url = "github:webosbrew/dev-manager-desktop";
    dev-manager-desktop.inputs.nixpkgs.follows = "nixpkgs-latest";
    dev-manager-desktop.inputs.nixpkgs-x86-darwin.follows = "nixpkgs-latest";
  };

  outputs =
    {
      nixpkgs-latest,
      nixpkgs-stable,
      home-manager,
      ...
    }@inputs:
    let
      # Home Manager imports interfaces from the Latest Channel, so its module
      # tree needs that channel's library plus the Home Manager extensions. The
      # outer System module trees keep their Release Channel libraries.
      lib = nixpkgs-latest.lib;
      homeManagerLib = import (home-manager + "/modules/lib/stdlib-extended.nix") lib;
      supportedSystems = [ "x86_64-linux" ];

      # Both channels share one config. `nixpkgs.pkgs` takes an already-built
      # instance, and NixOS asserts that `nixpkgs.config` is empty in that case,
      # so hosts cannot declare `allowUnfree` or insecure packages themselves.
      nixpkgsConfig = {
        allowUnfree = true;
        permittedInsecurePackages = [ ];
      };

      latestPkgsFor =
        system:
        import nixpkgs-latest {
          inherit system;
          config = nixpkgsConfig;
        };

      stablePkgsFor =
        system:
        import nixpkgs-stable {
          inherit system;
          config = nixpkgsConfig;
        };

      dotfilesPkgsFor =
        system:
        (import ./packages {
          inherit inputs;
          pkgs = latestPkgsFor system;
        });

      # Aggregates close over this flake's own inputs, so consumer flakes do
      # not re-declare them. Third-party modules are imported here because
      # `imports` cannot read module arguments.
      homeManagerModules.default = {
        _module.args = {
          dmsThemeSource = inputs.catppuccin-dms;
        };
        imports = [
          (import ./modules/coding-agents/composition.nix { inherit inputs stablePkgsFor; })
          ./modules/home-manager/default.nix
          inputs.neovim.homeManagerModules.default
          inputs.spicetify-nix.homeManagerModules.default
          inputs.hex.homeManagerModules.default
        ];
      };
      nixosModules.default = {
        imports = [
          (import ./modules/coding-agents/nixos.nix {
            inherit inputs stablePkgsFor;
            agentPkgs = latestPkgsFor "x86_64-linux";
          })
          ./modules/nixos/default.nix
          inputs.musnix.nixosModules.musnix
        ];
      };

      neovimChecks = system: inputs.neovim.checks.${system};

      serverMigrations = builtins.fromJSON (builtins.readFile ./checks/server-migrations.json);
      serverSource =
        migrated:
        let
          input = if migrated then nixpkgs-stable else inputs.nixpkgs-servers;
        in
        {
          input = if migrated then "nixpkgs-stable" else "nixpkgs-servers";
          revision = input.rev;
          channel =
            if migrated then
              (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs-stable.original.ref
            else
              null;
          kind = if migrated then "release" else "preserved";
        };
      serverSystem =
        host: migrated:
        let
          system = "x86_64-linux";
          source = serverSource migrated;
          nixpkgs = if migrated then nixpkgs-stable else inputs.nixpkgs-servers;
          pkgs-latest = latestPkgsFor system;
        in
        nixpkgs.lib.nixosSystem {
          specialArgs = lib.optionalAttrs (host == "homelab") {
            dotfilesPkgs =
              if migrated then dotfilesPkgsFor system else inputs.server-dotfiles-compat.dotfilesPkgs.${system};
          };
          modules = [
            (./hosts + "/${host}/configuration.nix")
            (import ./scripts/server-readiness/module.nix { inherit host source; })
            ({ lib, ... }: {
              nixpkgs.hostPlatform = system;
              nixpkgs.config = lib.optionalAttrs (!migrated) { allowUnfree = true; };
            })
          ]
          ++ lib.optionals migrated [
            { nixpkgs.pkgs = stablePkgsFor system; }
          ]
          ++ lib.optionals (host == "vps") [
            (if migrated then inputs.disko.nixosModules.disko else inputs.server-disko.nixosModules.disko)
          ]
          ++ lib.optionals (host == "homelab" && !migrated) [
            (import ./modules/coding-agents/nixos.nix {
              inherit inputs stablePkgsFor;
              agentPkgs = pkgs-latest;
            })
          ]
          ++ lib.optionals (host == "homelab") [
            (if migrated then nixosModules.default else inputs.server-dotfiles-compat.nixosModules.default)
            home-manager.nixosModules.home-manager
            ({ pkgs, ... }: {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-backup";
              home-manager.users.fveracoechea = {
                imports = [
                  homeManagerModules.default
                  ./hosts/homelab/home.nix
                ];
                _module.args.pkgs = pkgs-latest;
                home.enableNixpkgsReleaseCheck = false;
              };
              home-manager.extraSpecialArgs = {
                dotfilesPkgs = dotfilesPkgsFor system;
                pkgs-stable = pkgs;
                lib = homeManagerLib;
              };
            })
          ];
        };
      serverSystems = builtins.mapAttrs (
        host: status:
        assert builtins.elem status [
          "preserved"
          "release"
        ];
        serverSystem host (status == "release")
      ) serverMigrations;
      readinessManifest = host: migrated: system: {
        manifest = import ./scripts/server-readiness/manifest.nix {
          inherit host;
          inherit (system) config;
          inherit (system) pkgs;
          inherit (system) options;
          lib = system.pkgs.lib;
          source = serverSource migrated;
        };
        systemPath = system.config.system.build.toplevel.outPath;
        systemDrv = system.config.system.build.toplevel.drvPath;
      };
      serverReadiness = builtins.mapAttrs (
        host: system: readinessManifest host (serverMigrations.${host} == "release") system
      ) serverSystems;

      capabilityChecks =
        system:
        let
          args = {
            pkgs = latestPkgsFor system;
            desktop = inputs.self.nixosConfigurations.nixos-desktop.config;
            homelab = inputs.self.nixosConfigurations.homelab.config;
          };
        in
        (import ./modules/coding-agents/checks.nix args)
        // {
          home-manager-backups = import ./checks/home-manager-backups.nix {
            inherit (args) pkgs desktop;
          };
          server-readiness = import ./scripts/server-readiness/checks.nix {
            inherit (args) pkgs;
            manifests = builtins.mapAttrs (_: value: value.manifest) serverReadiness;
          };
        }
        // (import ./modules/shell/checks.nix args)
        // (import ./modules/networking/checks.nix args)
        // (import ./modules/hyprland/checks.nix args)
        // (import ./modules/gaming/checks.nix args)
        // (import ./modules/audio/checks.nix args);
    in
    {
      inherit homeManagerModules nixosModules;

      lib.serverReadiness = serverReadiness;
      lib.serverCandidates = builtins.mapAttrs (
        host: _: readinessManifest host true (serverSystem host true)
      ) serverMigrations;

      checks = builtins.listToAttrs (
        map (system: {
          name = system;
          value =
            (neovimChecks system) // lib.optionalAttrs (system == "x86_64-linux") (capabilityChecks system);
        }) supportedSystems
      );

      dotfilesPkgs = builtins.listToAttrs (
        map (system: {
          name = system;
          value = dotfilesPkgsFor system;
        }) supportedSystems
      );

      nixosConfigurations.homelab = serverSystems.homelab;
      nixosConfigurations.vps = serverSystems.vps;

      nixosConfigurations.nixos-desktop =
        let
          system = "x86_64-linux";
          pkgs-stable = stablePkgsFor system;
          pkgs-latest = latestPkgsFor system;
          specialArgs = {
            inherit pkgs-latest;
            dotfilesPkgs = dotfilesPkgsFor system;
          };
        in
        nixpkgs-stable.lib.nixosSystem {
          inherit specialArgs;

          modules = [
            nixosModules.default
            ./hosts/nixos-desktop/configuration.nix
            home-manager.nixosModules.home-manager
            {
              # System layer runs on the release channel.
              nixpkgs.hostPlatform = system;
              nixpkgs.pkgs = pkgs-stable;

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupCommand = pkgs-stable.writeShellScript "home-manager-backup" ''
                exec ${pkgs-stable.coreutils}/bin/mv --backup=numbered -- "$1" "$1.hm-backup"
              '';
              home-manager.users.fveracoechea = {
                imports = [
                  homeManagerModules.default
                  ./hosts/nixos-desktop/home.nix
                ];
                # Home layer runs on the latest channel. `useGlobalPkgs` hands
                # Home Manager the system `pkgs` at default priority, so this
                # plain definition replaces it.
                _module.args.pkgs = pkgs-latest;

                # Home Manager and `pkgs` are both on the Latest Channel. The
                # release check reads the System package set, so it still sees
                # the intentional channel split. See ADR-0007.
                home.enableNixpkgsReleaseCheck = false;
              };
              home-manager.extraSpecialArgs = specialArgs // {
                inherit pkgs-stable;
                lib = homeManagerLib;
              };
            }
          ];
        };
    };
}
