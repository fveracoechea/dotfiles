{
  description = "My fist NixOS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs";

    neovim-config.url = "github:fveracoechea/neovim-nix-config";
    neovim-config.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland?ref=refs/tags/v0.55.4";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    ultrashell.url = "github:fveracoechea/ultrashell";
    ultrashell.inputs.nixpkgs.follows = "nixpkgs";

    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    mcp-servers-nix.inputs.nixpkgs.follows = "nixpkgs";

    tmux-powerkit.url = "github:fabioluciano/tmux-powerkit";
    tmux-powerkit.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    home-manager,
    nix-darwin,
    ...
  } @ inputs: let
    supportedSystems = ["x86_64-linux" "aarch64-darwin"];

    customUtils = import ./utils;
    customPkgsFor = system: (import ./packages {
      inherit inputs system;
      pkgs = nixpkgs.legacyPackages.${system};
    });
    dotfilesPkgsFor = system: (import ./packages {
      inherit inputs system;
      pkgs = nixpkgs.legacyPackages.${system};
    });

    homeManagerModules = {
      default = ./modules/home-manager/default.nix;
      bat = ./modules/home-manager/bat.nix;
    };
    nixosModules = {
      default = ./modules/nixos/default.nix;
    };
    darwinModules = {
      default = ./modules/darwin/default.nix;
    };
  in {
    inherit homeManagerModules nixosModules darwinModules;

    dotfilesPkgs = builtins.listToAttrs (map (system: {
      name = system;
      value = dotfilesPkgsFor system;
    })
    supportedSystems);

    darwinConfigurations."macbook-pro" = nix-darwin.lib.darwinSystem rec {
      system = "aarch64-darwin";

      specialArgs = {
        inherit system inputs customUtils;
        customPkgs = customPkgsFor system;
        dotfilesPkgs = dotfilesPkgsFor system;
      };

      modules = [
        darwinModules.default
        ./hosts/macbook-pro/configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.users.franciscoveracoechea = import ./hosts/macbook-pro/home.nix;
          home-manager.extraSpecialArgs = specialArgs;
        }
      ];
    };

    nixosConfigurations.nixos-desktop = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";

      specialArgs = {
        inherit system inputs customUtils;
        customPkgs = customPkgsFor system;
        dotfilesPkgs = dotfilesPkgsFor system;
      };

      modules = [
        nixosModules.default
        ./hosts/nixos-desktop/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          nixpkgs.config.allowUnfree = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.users.fveracoechea = import ./hosts/nixos-desktop/home.nix;
          home-manager.extraSpecialArgs = specialArgs;
        }
      ];
    };
  };
}
