{
  pkgs,
  lib,
  ...
}: let
  path = "/share/themes/Colloid-Dark-Catppuccin/gtk-4.0";
  themePackage = pkgs.colloid-gtk-theme.override {
    tweaks = ["catppuccin"];
  };
in {
  xdg.enable = lib.mkDefault true;

  programs.mangohud = {
    enable = true;
    enableSessionWide = true;
  };

  # xdg.configFile."gtk-4.0/gtk.css".source = lib.mkForce "${themePackage}${path}/gtk.css";
  # xdg.configFile."gtk-4.0/gtk-dark.css".source = lib.mkForce "${themePackage}${path}/gtk-dark.css";
  # xdg.configFile."gtk-4.0/assets" = {
  #   source = lib.mkForce "${themePackage}${path}/assets";
  #   recursive = true;
  # };

  gtk = {
    enable = true;
    # theme = lib.mkForce {
    #   name = "Colloid-Dark-Catppuccin";
    #   package = themePackage;
    # };
    # iconTheme = lib.mkForce {
    #   name = "Colloid-dark";
    #   package = pkgs.colloid-icon-theme;
    # };
  };

  home.packages = with pkgs; [
    ripgrep
    eza
    yazi
    btop
    lazygit
    oh-my-posh
    fira-code-nerdfont
    neofetch
    python3
    cmatrix
    nurl
    kooha
    google-chrome
    dconf2nix
    deno
    watchman
    # gnome apps/extensions
    gnome-tweaks
    dconf-editor
    gnomeExtensions.freon
    gnomeExtensions.gamemode-shell-extension
    gnomeExtensions.tiling-shell
    gnomeExtensions.dash-to-dock
    gnomeExtensions.blur-my-shell
    gnomeExtensions.system-monitor
    gnomeExtensions.workspace-indicator
    gnomeExtensions.auto-move-windows
  ];
}
