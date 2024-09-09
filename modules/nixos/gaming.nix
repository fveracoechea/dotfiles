{pkgs, ...}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = ["modesetting"];
  hardware.amdgpu.initrd.enable = true;

  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;

  programs.gamemode.enable = true;

  hardware.cpu.amd.updateMicrocode = true;

  environment.systemPackages = with pkgs; [
    protonup
    lutris
    amdgpu_top
  ];

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };
}
