{pkgs, ...}: {
  hardware = {
    graphics.extraPackages = [pkgs.gamescope-wsi];
    cpu.amd.updateMicrocode = true;
    amdgpu.initrd.enable = true;
    xone.enable = true;
  };

  programs = {
    steam.enable = true;
    steam.protontricks.enable = true;
    steam.extraCompatPackages = [pkgs.proton-ge-bin];
    steam.gamescopeSession = {
      enable = true;
      env = {
        DXVK_HDR = "1";
        ENABLE_HDR = "1";
      };
      args = [
        "--adaptive-sync" # VRR support
        "--hdr-enabled" # HDR
        "--hdr-itm-enable"
        "--rt" # Real time scheduling
        "-W 2560"
        "-H 1440"
        "-r 120" # Refresh rate
        "-f" # Fullscreen
        # "-O DP-1" # Output display
      ];
    };

    gamemode.enable = true;
    gamescope.enable = true;
    gamescope.capSysNice = false;
  };

  environment = {
    sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };
    systemPackages = with pkgs; [
      # lutris
      mesa-demos
      ethtool
      protonup-ng
      amdgpu_top
      mangohud
      lact
    ];
  };

  systemd.services.lact = {
    enable = true;
    description = "AMDGPU Control Daemon";
    after = ["multi-user.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pkgs.lact}/bin/lact daemon";
    };
  };

  services = {
    hardware.openrgb.enable = true;

    sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };
  };
}
