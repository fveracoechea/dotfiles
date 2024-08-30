{
  description = "My fist NixOS Flake";

  inputs = {
    # NixOS official package source, using the nixos-24.05 branch here
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    # Unstable packages
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # alejandra nix formatter
    alejandra = {
      url = "github:kamadorueda/alejandra/3.0.0";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # home-manager, used for managing user configuration -
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    # Sylix
    stylix = {
      url = "github:danth/stylix/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    nixpkgs-unstable,
    stylix,
    ...
  } @ inputs: {
    # The host with the hostname `nixos-vm` will use this configuration
    nixosConfigurations.nixos-vm = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";

      specialArgs = {
        inherit inputs;
        # Configure parameters to use nixpkgs-unstable
        unstable = import nixpkgs-unstable {
          # Refer to the `system` parameter form the outer scope
          inherit system;
          config.allowUnfree = true;
        };
      };

      modules = [
        stylix.nixosModules.stylix

        # NixOS System configurations
        ./hosts/nixos-vm/configuration.nix

        # make home-manager as a module of nixos
        # so that home-manager configuration will be deployed automatically
        # when executing `nixos-rebuild switch`
        home-manager.nixosModules.home-manager

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.fveracoechea = import ./hosts/nixos-vm/home.nix;
          # extraSpecialArgs passes arguments to home.nix
          home-manager.extraSpecialArgs = specialArgs;
        }
      ];
    };
  };
}