{
  pkgs,
  pkgs-latest,
  lib,
  config,
  ...
}: {
  options.dotfiles.gaming.enable = lib.mkEnableOption "gaming suite (steam, gamescope, sunshine, openrgb, AMD tools)";

  config = lib.mkIf config.dotfiles.gaming.enable {
    # Gaming packages take the Latest Channel even though this module sits in
    # the system layer. Routed through package options; GameMode is the one
    # exception: its NixOS module exposes no package option.
    # See ADR-0007.
    hardware.graphics.extraPackages = [pkgs-latest.gamescope-wsi];

    programs = {
      steam = {
        enable = true;
        package = pkgs-latest.steam;
        protontricks = {
          enable = true;
          package = pkgs-latest.protontricks;
        };
        extraCompatPackages = [pkgs-latest.proton-ge-bin];
        gamescopeSession = {
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
            "-O HDMI-A-1" # Output display (dummy plug, sunshine capture target)
          ];
        };
      };

      gamemode.enable = true;
      gamescope = {
        enable = true;
        # Also serves the Steam Session: its script calls `gamescope` from PATH.
        package = pkgs-latest.gamescope;
        capSysNice = false;
      };
    };

    environment = {
      sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
      };
      systemPackages = [
        pkgs.ethtool
        pkgs-latest.lact
      ];
    };

    systemd.services.lact = {
      enable = true;
      description = "AMDGPU Control Daemon";
      after = ["multi-user.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkgs-latest.lact}/bin/lact daemon";
      };
    };

    services = {
      hardware.openrgb = {
        enable = true;
        package = pkgs-latest.openrgb;
      };

      # Super+Alt+Q blindly ends the Steam Session (kills gamescope,
      # session script exits, Ly greeter returns). evdev-level, works in any session
      keyd = {
        enable = true;
        keyboards.default = {
          ids = ["*"];
          settings."control+alt".q = "command(${pkgs.util-linux}/bin/logger -t steam-exit combo fired, killing gamescope; ${pkgs.procps}/bin/pkill -x gamescope || ${pkgs.procps}/bin/pkill -x .gamescope-wrap)";
        };
      };

      sunshine = {
        enable = true;
        package = pkgs-latest.sunshine;
        # Started via nixos-fake-graphical-session.target (Steam Session only);
        # Hyprland is uwsm-managed and never activates that target
        autoStart = false;
        capSysAdmin = true;
        openFirewall = true;
      };
    };

    # Sunshine probes encoders once at startup; give gamescope time to take DRM
    # and modeset the Dummy Plug first, or probing fails until Sunshine restarts
    systemd.user.services.sunshine = {
      wantedBy = ["nixos-fake-graphical-session.target"];
      after = ["nixos-fake-graphical-session.target"];
      serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
    };
  };
}
