{
  inputs,
  pkgs,
  ...
}: {
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  environment.systemPackages = with pkgs; [
    dunst
    libnotify
    hyprdim
    wl-clipboard
    pavucontrol
    networkmanagerapplet
    nautilus
    gnome-system-monitor
    gnome-calculator
    gnome.gnome-control-center
    gnome.gnome-weather
    gnome.gnome-clocks
  ];

  # Optional, hint Electron apps to use Wayland:
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
