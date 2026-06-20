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
      aerospace = ./modules/home-manager/aerospace.nix;
      bat = ./modules/home-manager/bat.nix;
      btop = ./modules/home-manager/btop.nix;
      desktop-entries = ./modules/home-manager/desktop-entries/default.nix;
      fonts = ./modules/home-manager/fonts.nix;
      ghostty = ./modules/home-manager/ghostty.nix;
      git = ./modules/home-manager/git.nix;
      gtk = ./modules/home-manager/gtk.nix;
      hyprland = ./modules/home-manager/hyprland/default.nix;
      karabiner = ./modules/home-manager/karabiner.nix;
      lazygit = ./modules/home-manager/lazygit.nix;
      lazydocker = ./modules/home-manager/lazydocker.nix;
      oh-my-posh = ./modules/home-manager/oh-my-posh.nix;
      opencode = ./modules/home-manager/opencode/default.nix;
      pro-audio = ./modules/home-manager/pro-audio.nix;
      spotify = ./modules/home-manager/spotify.nix;
      ssh = ./modules/home-manager/ssh.nix;
      sunshine = ./modules/home-manager/sunshine.nix;
      shell = ./modules/home-manager/shell.nix;
      tmux = ./modules/home-manager/tmux/default.nix;
      volta = ./modules/home-manager/volta.nix;
      yazi = ./modules/home-manager/yazi.nix;
      zsh = ./modules/home-manager/zsh.nix;
    };
    nixosModules = {
      default = ./modules/nixos/default.nix;
      bootloader = ./modules/nixos/bootloader.nix;
      display-manager = ./modules/nixos/display-manager.nix;
      gaming = ./modules/nixos/gaming.nix;
      hyprland = ./modules/nixos/hyprland.nix;
      misc = ./modules/nixos/misc.nix;
      networking = ./modules/nixos/networking.nix;
      nix-ld = ./modules/nixos/nix-ld.nix;
      ollama = ./modules/nixos/ollama.nix;
      pipewire = ./modules/nixos/pipewire.nix;
      timezone = ./modules/nixos/timezone.nix;
      zsh-shell = ./modules/nixos/zsh-shell.nix;
    };
    darwinModules = {
      default = ./modules/darwin/default.nix;
      homebrew = ./modules/darwin/homebrew.nix;
      system-defaults = ./modules/darwin/system-defaults.nix;
      zsh-shell = ./modules/darwin/zsh-shell.nix;
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
