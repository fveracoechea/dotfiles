{pkgs, ...}: let
  username = "fveracoechea";
in {
  imports = [
    ../../modules/darwin/default.nix
  ];

  dotfiles = {
    homebrew.enable = true;
    darwin-system-config.enable = true;
    system-shell.enable = true;
  };

  system.primaryUser = username;

  # Used for backwards compatibility.
  system.stateVersion = 5;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nix;
    settings.experimental-features = ["nix-command" "flakes"];
    optimise.automatic = true;
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
  };

  users.users = {
    ${username} = {
      name = username;
      home = "/Users/${username}";
    };
  };

  # Enable touch id
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;
}
