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

    tmux-powerkit.url = "github:fabioluciano/tmux-powerkit";
    tmux-powerkit.inputs.nixpkgs.follows = "nixpkgs";

    hunk.url = "github:modem-dev/hunk";
    hunk.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    home-manager,
    nix-darwin,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;
    supportedSystems = ["x86_64-linux" "aarch64-darwin"];

    dotfilesPkgsFor = system: (import ./packages {
      inherit inputs system;
      pkgs = nixpkgs.legacyPackages.${system};
    });

    homeManagerModules.default = ./modules/home-manager/default.nix;
    nixosModules.default = ./modules/nixos/default.nix;
    darwinModules.default = ./modules/darwin/default.nix;

    neovimChecks = system:
      import ./checks/neovim.nix {
        inherit lib inputs system;
        pkgs = nixpkgs.legacyPackages.${system};
      };
  in {
    inherit homeManagerModules nixosModules darwinModules;

    checks = builtins.listToAttrs (map (system: {
        name = system;
        value = neovimChecks system;
      })
      supportedSystems);

    dotfilesPkgs = builtins.listToAttrs (map (system: {
        name = system;
        value = dotfilesPkgsFor system;
      })
      supportedSystems);

    darwinConfigurations.macbook-pro = let
      system = "aarch64-darwin";
      specialArgs = {
        inherit inputs;
        dotfilesPkgs = dotfilesPkgsFor system;
      };
    in
      nix-darwin.lib.darwinSystem {
        inherit specialArgs;

        modules = [
          darwinModules.default
          ./hosts/macbook-pro/configuration.nix
          home-manager.darwinModules.home-manager
          {
            nixpkgs.hostPlatform = system;
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.franciscoveracoechea = import ./hosts/macbook-pro/home.nix;
            home-manager.extraSpecialArgs = specialArgs;
          }
        ];
      };

    nixosConfigurations.nixos-desktop = let
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        dotfilesPkgs = dotfilesPkgsFor system;
      };
    in
      nixpkgs.lib.nixosSystem {
        inherit specialArgs;

        modules = [
          nixosModules.default
          ./hosts/nixos-desktop/configuration.nix
          home-manager.nixosModules.home-manager
          {
            nixpkgs.hostPlatform = system;
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
