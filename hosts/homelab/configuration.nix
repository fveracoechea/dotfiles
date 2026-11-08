{...}: {
  imports = [
    ./hardware-configuration.nix
    ./services/adguardhome.nix
    ./services/caddy.nix
    ./services/home-assistant.nix
    ./services/immich.nix
    ./services/ollama.nix
    ./services/paperless.nix
    ./services/paperless-gpt.nix
    ./services/postgresql.nix
    ./services/tailscale.nix
    ./services/vaultwarden.nix
    ./services/zwave-js.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix = {
    gc.automatic = true;
    optimise.automatic = true;
    gc.options = "--delete-older-than 30d";
    settings.experimental-features = ["nix-command" "flakes"];
    settings.trusted-users = ["root" "@wheel"];
  };

  security.sudo.wheelNeedsPassword = false;

  dotfiles = {
    system-shell.enable = true;
    timezone.enable = true;
  };

  networking = {
    firewall.enable = true;
    hostName = "homelab";
    wireless.enable = true;
    networkmanager.enable = true;
  };

  programs.ssh.startAgent = true;
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      X11Forwarding = false;
    };
  };

  users.users.fveracoechea = {
    password = "12345";
    isNormalUser = true;
    description = "Francisco Veracoechea";
    extraGroups = ["wheel" "networkmanager"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3gt/1eR57Gx6gI2PMyXcu0gMCq708ttjP54TLwR/fh fveracoechea@nixos"
    ];
  };

  system.stateVersion = "26.05";
}
