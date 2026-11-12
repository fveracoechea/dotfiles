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
    server-home-manager.url = "github:nix-community/home-manager/e13ba5e5abbd9b912fa8c6979bd119e87ca7fdd9";
    server-home-manager.inputs.nixpkgs.follows = "nixpkgs-servers";
    server-disko.url = "github:nix-community/disko/ff8702b4de27f72b4c78573dfb89ec74e36abdf1";
    server-disko.inputs.nixpkgs.follows = "nixpkgs-servers";
    server-dotfiles-compat.url = "github:fveracoechea/dotfiles/a4ede6eddbb6f3bc3b8c98cff0d86c99661f0f46";
    server-dotfiles-compat.inputs.nixpkgs.follows = "nixpkgs-servers";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-latest";

    neovim.url = "github:fveracoechea/neovim";
    neovim.inputs.nixpkgs.follows = "nixpkgs-latest";
    neovim.inputs.home-manager.follows = "home-manager";

    dms.url = "github:AvengeMedia/DankMaterialShell/stable";
    dms.inputs.nixpkgs.follows = "nixpkgs-latest";

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

  outputs = {
    nixpkgs-latest,
    nixpkgs-stable,
    home-manager,
    ...
  } @ inputs: let
    # Home Manager imports interfaces from the Latest Channel, so its module
    # tree needs that channel's library plus the Home Manager extensions. The
    # outer System module trees keep their Release Channel libraries.
    lib = nixpkgs-latest.lib;
    homeManagerLib = import (home-manager + "/modules/lib/stdlib-extended.nix") lib;
    supportedSystems = ["x86_64-linux"];

    # Both channels share one config. `nixpkgs.pkgs` takes an already-built
    # instance, and NixOS asserts that `nixpkgs.config` is empty in that case,
    # so hosts cannot declare `allowUnfree` or insecure packages themselves.
    nixpkgsConfig = {
      allowUnfree = true;
      permittedInsecurePackages = [];
    };

    latestPkgsFor = system:
      import nixpkgs-latest {
        inherit system;
        config = nixpkgsConfig;
      };

    stablePkgsFor = system:
      import nixpkgs-stable {
        inherit system;
        config = nixpkgsConfig;
      };

    dotfilesPkgsFor = system: (import ./packages {
      inherit inputs;
      pkgs = latestPkgsFor system;
    });

    # Aggregates close over this flake's own inputs, so consumer flakes do
    # not re-declare them. Third-party modules are imported here because
    # `imports` cannot read module arguments.
    homeManagerModules.default = {
      _module.args = {
        dmsThemeSource = inputs.catppuccin-dms;
        dmsSource = inputs.dms;
      };
      imports = [
        (import ./modules/coding-agents/composition.nix {inherit inputs stablePkgsFor;})
        ./modules/home-manager/default.nix
        inputs.neovim.homeManagerModules.default
        inputs.dms.homeModules.dank-material-shell
        inputs.spicetify-nix.homeManagerModules.default
        inputs.hex.homeManagerModules.default
      ];
    };
    nixosModules.default = {
      imports = [
        ./modules/nixos/default.nix
        inputs.musnix.nixosModules.musnix
      ];
    };

    neovimChecks = system: inputs.neovim.checks.${system};

    hyprlandChecks = system:
      import ./checks/hyprland.nix {
        inherit lib inputs;
        pkgs = latestPkgsFor system;
        pkgs-stable = stablePkgsFor system;
      };

    homelabSpecialArgs = {
      serverDotfiles = inputs.server-dotfiles-compat;
      dotfilesPkgs = inputs.server-dotfiles-compat.dotfilesPkgs.x86_64-linux;
    };

    hostChecks = import ./checks/hosts.nix {
      inherit lib inputs;
      hosts = inputs.self.nixosConfigurations;
      pkgs = latestPkgsFor "x86_64-linux";
    };

    codingAgentChecks = system:
      import ./modules/coding-agents/checks.nix {
        inherit lib home-manager;
        pkgs = latestPkgsFor system;
        homeModule = homeManagerModules.default;
        dotfilesPkgs = dotfilesPkgsFor system;
        pkgs-stable = stablePkgsFor system;
      };
  in {
    inherit homeManagerModules nixosModules;

    lib.hostManifests = hostChecks.manifests;
    lib.serverPreservation = hostChecks.preservation;
    lib.serverPreservationNegativeCases = hostChecks.negativeCases;

    checks = builtins.listToAttrs (map (system: {
        name = system;
        value =
          (neovimChecks system)
          // lib.optionalAttrs (system == "x86_64-linux") (
            (hyprlandChecks system) // (codingAgentChecks system) // {host-preservation = hostChecks.check;}
          );
      })
      supportedSystems);

    dotfilesPkgs = builtins.listToAttrs (map (system: {
        name = system;
        value = dotfilesPkgsFor system;
      })
      supportedSystems);

    nixosConfigurations.homelab = inputs.nixpkgs-servers.lib.nixosSystem {
      specialArgs = homelabSpecialArgs;
      modules = [
        ./hosts/homelab/configuration.nix
        inputs.server-dotfiles-compat.nixosModules.default
        inputs.server-home-manager.nixosModules.home-manager
        {
          nixpkgs.hostPlatform = "x86_64-linux";
          nixpkgs.config.allowUnfree = true;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.users.fveracoechea = import ./hosts/homelab/home.nix;
          home-manager.extraSpecialArgs = homelabSpecialArgs;
        }
      ];
    };
    nixosConfigurations.vps = inputs.nixpkgs-servers.lib.nixosSystem {
      modules = [
        inputs.server-disko.nixosModules.disko
        ./hosts/vps/configuration.nix
        {
          nixpkgs.hostPlatform = "x86_64-linux";
          nixpkgs.config.allowUnfree = true;
        }
      ];
    };

    nixosConfigurations.nixos-desktop = let
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
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.fveracoechea = {
              imports = [homeManagerModules.default ./hosts/nixos-desktop/home.nix];
              # Home layer runs on the latest channel. `useGlobalPkgs` hands
              # Home Manager the system `pkgs` at default priority, so this
              # plain definition replaces it.
              _module.args.pkgs = pkgs-latest;

              # Home Manager and `pkgs` are both on the Latest Channel. The
              # release check reads the System package set, so it still sees
              # the intentional channel split. See ADR-0007.
              home.enableNixpkgsReleaseCheck = false;
            };
            home-manager.extraSpecialArgs =
              specialArgs
              // {
                inherit pkgs-stable;
                lib = homeManagerLib;
              };
          }
        ];
      };
  };
}
