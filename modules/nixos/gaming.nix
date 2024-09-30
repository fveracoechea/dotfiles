{pkgs, ...}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = ["modesetting"];

  services.xserver.deviceSection = ''
    Option "VariableRefresh" "true"
  '';

  hardware.amdgpu.initrd.enable = true;

  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;

  programs.gamemode.enable = true;

  hardware.cpu.amd.updateMicrocode = true;

  environment.systemPackages = with pkgs; [
    protonup
    amdgpu_top
    discord
    lact
    gamemode
    gnomeExtensions.gamemode-shell-extension
    (lutris.override {
      extraPkgs = pkgs: [
        wineWowPackages.waylandFull
        winetricks
      ];
    })
  ];

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };
}
