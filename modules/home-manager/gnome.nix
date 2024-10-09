{
  pkgs,
  lib,
  ...
}: let
in {
  xdg.enable = lib.mkDefault true;

  programs.mangohud = {
    enable = true;
    enableSessionWide = true;
  };

  gtk = {
    enable = true;
    iconTheme = lib.mkForce {
      name = "Colloid-Catppuccin-Dark";
      package = pkgs.colloid-icon-theme.override {
        schemeVariants = ["catppuccin"];
      };
    };
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
