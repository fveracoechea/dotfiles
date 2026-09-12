{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  dotfiles = {
    bootloader.enable = true;
    display-manager.enable = true;
    docker.enable = true;
    tailscale-client.enable = true;
    system-shell.enable = true;
    nix-ld.enable = true;
    timezone.enable = true;
    pipewire.enable = true;
    gaming.enable = true;
    handy.enable = true;
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
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "docker"
      "dialout"
      "plugdev"
      "input"
      "uinput"
      "video"
    ];
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

  # Device access for Kinesis Advantage360 Pro.
  services.udev.extraRules = ''
    ATTRS{idVendor}=="29ea", MODE="0660", GROUP="plugdev", TAG+="uaccess"
  '';

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
  ];

  # DO NOT CHANGE
  system.stateVersion = "24.05";
}
