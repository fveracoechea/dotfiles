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

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-latest";

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

    operator.url = "github:fveracoechea/operator/v2.2.2";
    operator.inputs.nixpkgs.follows = "nixpkgs-latest";

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

    codingAgentSources = {
      inherit (inputs) herdr hunk operator;
    };

    # Aggregates close over this flake's own inputs, so consumer flakes do
    # not re-declare them. Third-party modules are imported here because
    # `imports` cannot read module arguments.
    homeManagerModules.default = {
      _module.args = {
        inherit codingAgentSources;
        dmsThemeSource = inputs.catppuccin-dms;
        dmsSource = inputs.dms;
      };
      imports = [
        ./modules/home-manager/default.nix
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

    neovimChecks = system:
      import ./checks/neovim.nix {
        inherit lib inputs system;
        pkgs = latestPkgsFor system;
      };

    hyprlandChecks = system:
      import ./checks/hyprland.nix {
        inherit lib inputs;
        pkgs = latestPkgsFor system;
        pkgs-stable = stablePkgsFor system;
      };
  in {
    inherit homeManagerModules nixosModules;

    checks = builtins.listToAttrs (map (system: {
        name = system;
        value = (neovimChecks system) // lib.optionalAttrs (system == "x86_64-linux") (hyprlandChecks system);
      })
      supportedSystems);

    dotfilesPkgs = builtins.listToAttrs (map (system: {
        name = system;
        value = dotfilesPkgsFor system;
      })
      supportedSystems);

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
