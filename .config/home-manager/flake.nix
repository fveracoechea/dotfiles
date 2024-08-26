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
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixpkgs-unstable,
    alejandra,
    ...
  } @ inputs: {
    # The host with the hostname `desktop` will use this configuration
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";

      specialArgs = {
        # Configure parameters to use nixpkgs-unstable
        unstable = import nixpkgs-unstable {
          # Refer to the `system` parameter form the outer scope
          inherit system;
          config.allowUnfree = true;
        };
      };

      modules = [
        # Import previous configuration used,
        # so the old configuration file still takes effect
        ./configuration.nix

        {
          environment.systemPackages = [alejandra.defaultPackage.${system}];
        }

        # make home-manager as a module of nixos
        # so that home-manager configuration will be deployed automatically
        # when executing `nixos-rebuild switch`
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.fveracoechea = import ./home.nix;

          # extraSpecialArgs passes arguments to home.nix
          home-manager.extraSpecialArgs = specialArgs;
        }
      ];
    };
  };
}
