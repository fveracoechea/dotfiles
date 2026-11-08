{
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko-config.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./services/caddy.nix
    ./services/fail2ban.nix
    ./services/headplane.nix
    ./services/headscale.nix
    ./services/tailscale.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  nix = {
    gc.automatic = true;
    optimise.automatic = true;
    gc.options = "--delete-older-than 10d";
    settings.experimental-features = ["nix-command" "flakes"];
    settings.trusted-users = ["root" "@wheel"];
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      AllowUsers = ["fveracoechea"];
      KbdInteractiveAuthentication = false;
      LoginGraceTime = 30;
      MaxAuthTries = 3;
      MaxStartups = "10:30:30";
      PermitRootLogin = "no";
      PerSourceMaxStartups = 3;
      PasswordAuthentication = false;
      X11Forwarding = false;
    };
  };
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  environment.systemPackages = with pkgs; [wget curl git fastfetch nano btop neovim];
  security.sudo.wheelNeedsPassword = false;

  users.users.fveracoechea = {
    password = "12345";
    isNormalUser = true;
    description = "Francisco Veracoechea";
    extraGroups = ["wheel" "networkmanager"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3gt/1eR57Gx6gI2PMyXcu0gMCq708ttjP54TLwR/fh fveracoechea@nixos"
    ];
  };
  system.stateVersion = "24.05";
}
