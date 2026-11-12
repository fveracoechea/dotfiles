{ ... }: {
  imports = [
    ../core/palette.nix

    ./neovim.nix
    ../shell/bat.nix
    ../shell/btop.nix
    ./desktop-entries
    ./fonts.nix
    ./fuzzel.nix
    ../gaming/home.nix
    ./ghostty.nix
    ../shell/git.nix
    ./gtk.nix
    ./hex.nix
    ../hyprland/home.nix
    ../gaming/mangohud.nix
    ../coding-agents/home.nix
    ../audio/home.nix
    ../shell/home.nix
    ./spotify.nix
    ../gaming/sunshine.nix
    ../shell/tmux
    ./volta.nix
    ../shell/yazi.nix
    ../shell/zsh.nix
  ];
}
