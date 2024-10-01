{...}: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Optional, hint Electron apps to use Wayland:
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
