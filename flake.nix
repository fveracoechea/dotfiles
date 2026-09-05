{
  description = "My fist NixOS Flake";

  inputs = {
    # Latest channel: apps, CLI, and tooling. `nixpkgs-unstable`, not
    # `nixos-unstable`: this input no longer builds a NixOS system, so the
    # NixOS VM integration tests that gate `nixos-unstable` validate nothing
    # it provides, and upstream recommends this branch for darwin and home
    # use. See ADR-0007.
    nixpkgs-latest.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Release channel: system packages and services. The release has a separate
    # branch per platform, and nix-darwin requires the darwin one.
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-stable-darwin.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-latest";

    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs-stable";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs-latest";

    # Pinned to the release branch to match `nixpkgs-stable-darwin`:
    # nix-darwin asserts that the two branches correspond.
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-stable-darwin";

    ultrashell.url = "github:fveracoechea/ultrashell";
    ultrashell.inputs.nixpkgs.follows = "nixpkgs-stable";

    tmux-powerkit.url = "github:fabioluciano/tmux-powerkit";
    tmux-powerkit.inputs.nixpkgs.follows = "nixpkgs-latest";

    hunk.url = "github:modem-dev/hunk";
    hunk.inputs.nixpkgs.follows = "nixpkgs-latest";

    figma-plugin.url = "github:figma/mcp-server-guide";
    figma-plugin.flake = false;

    herdr.url = "github:herdrdev/herdr";
    herdr.inputs.nixpkgs.follows = "nixpkgs-latest";
  };

  outputs = {
    nixpkgs-latest,
    nixpkgs-stable,
    nixpkgs-stable-darwin,
    home-manager,
    nix-darwin,
    ...
  } @ inputs: let
    lib = nixpkgs-latest.lib;
    supportedSystems = ["x86_64-linux" "aarch64-darwin"];

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

    # One release, two QA branches: `nixos-*` for Linux, `nixpkgs-*-darwin`
    # for macOS. The system picks the branch so every call site stays one line.
    stableSourceFor = system:
      if lib.hasSuffix "darwin" system
      then nixpkgs-stable-darwin
      else nixpkgs-stable;

    stablePkgsFor = system:
      import (stableSourceFor system) {
        inherit system;
        config = nixpkgsConfig;
      };

    dotfilesPkgsFor = system: (import ./packages {
      inherit inputs;
      pkgs = latestPkgsFor system;
    });

    codingAgentSources = {
      inherit (inputs) figma-plugin herdr hunk;
    };

    # Aggregates close over this flake's own inputs, so consumer flakes do
    # not re-declare them. Third-party modules are imported here because
    # `imports` cannot read module arguments.
    homeManagerModules.default = {
      _module.args = {inherit codingAgentSources;};
      imports = [
        ./modules/home-manager/default.nix
        inputs.spicetify-nix.homeManagerModules.default
      ];
    };
    nixosModules.default = {
      imports = [
        ./modules/nixos/default.nix
        inputs.musnix.nixosModules.musnix
      ];
    };
    darwinModules.default = {
      imports = [
        ./modules/darwin/default.nix
        # Installs into environment.systemPackages so nix-darwin links
        # Spotify.app into /Applications/Nix Apps for Spotlight/Launchpad.
        inputs.spicetify-nix.darwinModules.default
      ];
    };

    neovimChecks = system:
      import ./checks/neovim.nix {
        inherit lib inputs system;
        pkgs = latestPkgsFor system;
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
      pkgs-stable = stablePkgsFor system;
      pkgs-latest = latestPkgsFor system;
      specialArgs = {
        inherit pkgs-latest;
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
            # System layer runs on the release channel.
            nixpkgs.hostPlatform = system;
            nixpkgs.pkgs = pkgs-stable;

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.fveracoechea = {
              imports = [homeManagerModules.default ./hosts/macbook-pro/home.nix];
              # Home layer runs on the latest channel. `useGlobalPkgs` hands
              # Home Manager the system `pkgs` at default priority, so this
              # plain definition replaces it.
              _module.args.pkgs = pkgs-latest;

              # Home Manager and `pkgs` are both on the latest channel, but the
              # nix-darwin module tree evaluates Home Manager with the release
              # channel's `lib`. That third-party mismatch is deliberate and
              # unavoidable here. See ADR-0007.
              home.enableNixpkgsReleaseCheck = false;
            };
            home-manager.extraSpecialArgs = specialArgs // {inherit pkgs-stable;};
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

              # Home Manager and `pkgs` are both on the latest channel, but the
              # NixOS module tree evaluates Home Manager with the release
              # channel's `lib`. That third-party mismatch is deliberate and
              # unavoidable here. See ADR-0007.
              home.enableNixpkgsReleaseCheck = false;
            };
            home-manager.extraSpecialArgs = specialArgs // {inherit pkgs-stable;};
          }
        ];
      };
  };
}
