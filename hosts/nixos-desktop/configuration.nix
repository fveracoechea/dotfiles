{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/default.nix
  ];

  dotfiles = {
    hyprland.enable = true;
  };

  nix = {
    optimise.automatic = true;
    settings.experimental-features = ["nix-command" "flakes" "impure-derivations" "ca-derivations"];
    gc.automatic = true;
    gc.options = "--delete-older-than 30d";
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024; # 16GB
    }
  ];

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
    videoDrivers = ["modesetting"];
  };

  users.users.fveracoechea = {
    isNormalUser = true;
    description = "fveracoechea";
    extraGroups = ["networkmanager" "wheel" "audio" "docker" "dialout" "plugdev"];
  };

  virtualisation.docker.enable = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "beekeeper-studio-5.3.4"
    "beekeeper-studio-5.5.5"
    "beekeeper-studio-5.5.7"
  ];

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    curl
    zip
    unzip
    cmake
    gnumake
    cargo
    openssl
    lazydocker
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
