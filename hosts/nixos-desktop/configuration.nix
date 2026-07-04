{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/default.nix
  ];

  dotfiles = {
    bootloader.enable = true;
    display-manager.enable = true;
    docker.enable = true;
    tailscale-client = true;
    system-shell.enable = true;
    nix-ld.enable = true;
    timezone.enable = true;
    pipewire.enable = true;
    gaming.enable = true;
    hyprland.enable = true;
    networking.enable = true;
  };

  nix = {
    optimise.automatic = true;
    settings.experimental-features = ["nix-command" "flakes"];
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

  # Firmware updates
  services.fwupd.enable = true;

  # Browser
  programs.firefox.enable = true;

  # Printing
  services.printing.enable = true;

  # Enable the system-wide SSH agent
  programs.ssh.startAgent = true;

  # Virtual file system support (e.g., Trash can)
  services.gvfs.enable = true;

  # udev rule for Kinesis Advantage360 Pro serial access (idVendor 29ea)
  services.udev.extraRules = ''
    ATTRS{idVendor}=="29ea", MODE="0660", GROUP="plugdev", TAG+="uaccess"
  '';

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
  ];

  # DO NOT CHANGE
  system.stateVersion = "24.05";
}
