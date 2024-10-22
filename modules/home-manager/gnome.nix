{
  pkgs,
  lib,
  ...
}: {
  xdg.enable = lib.mkDefault true;

  programs.mangohud = {
    enable = true;
    enableSessionWide = true;
  };

  gtk = {
    enable = true;
    iconTheme = lib.mkForce {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "blue";
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
    watchman
    vesktop
    dconf-editor
    gnome-tweaks
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
