{
  pkgs,
  lib,
  ...
}: {
  gtk = {
    enable = true;
    theme = lib.mkForce {
      name = "Colloid-Dark-Catppuccin";
      package = pkgs.colloid-gtk-theme.override {
        tweaks = ["catppuccin"];
      };
    };
    iconTheme = lib.mkForce {
      name = "Colloid-dark";
      package = pkgs.colloid-icon-theme;
    };
  };

  home.packages = with pkgs; [
    ripgrep
    eza
    yazi
    btop
    lazygit
    oh-my-posh
    volta
    fira-code-nerdfont
    neofetch
    python3
    cmatrix
    nurl
    kooha
    slack
    google-chrome
    dconf2nix
    deno
    neovim
    # gnome extensions
    gnome.gnome-tweaks
    gnome.dconf-editor
    gnomeExtensions.freon
    gnomeExtensions.dash2dock-lite
    gnomeExtensions.blur-my-shell
    gnomeExtensions.system-monitor
    gnomeExtensions.workspace-indicator
    gnomeExtensions.auto-move-windows
  ];
}
