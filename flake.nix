{
  description = "My fist NixOS Flake";

  inputs = {
    # NixOS official package sources
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/release-24.05";

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Sylix - system wide styles
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim config flake
    neovim-config = {
      url = "github:fveracoechea/neovim-nix-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # tmux weather plugin
    tmux-clima = {
      url = "github:vascomfnunes/tmux-clima";
      flake = false;
    };

    # alejandra nix formatter
    alejandra = {
      url = "github:kamadorueda/alejandra/3.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland
    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Spotify theme
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nixpkgs-stable,
    stylix,
    home-manager,
    ...
  } @ inputs: {
    # The host with the hostname `nixos-desktop` will use this configuration
    nixosConfigurations.nixos-desktop = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";

      specialArgs = {
        inherit inputs;
        # Configure parameters to use nixpkgs-unstable
        pkgs-stable = import nixpkgs-stable {
          # Refer to the `system` parameter form the outer scope
          inherit system;
          config.allowUnfree = true;
        };
      };

      modules = [
        stylix.nixosModules.stylix
        # NixOS System configurations
        ./hosts/nixos-desktop/configuration.nix
        # make home-manager as a module of nixos
        # so tat home-manager configuration will be deployed automatically
        # when executing `nixos-rebuild switch`
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.users.fveracoechea = import ./hosts/nixos-desktop/home.nix;
          home-manager.extraSpecialArgs = specialArgs;
        }
      ];
    };
  };
}
