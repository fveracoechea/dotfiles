{
  pkgs,
  dotfilesPkgs,
  ...
}: {
  imports = [
    ../../modules/home-manager/default.nix
  ];

  dotfiles = {
    shell.enable = true;
    neovim.enable = true;
    gtk.enable = true;
    volta.enable = true;
    ghostty.enable = true;
    sunshine.enable = true;
    fonts.enable = true;
    spotify.enable = true;
    opencode.enable = true;
    desktop-entries.enable = true;
    pro-audio.enable = true;
    fuzzel.enable = true;
    hyprland = {
      enable = true;
      monitors = [
        "DP-1, 5120x1440@119.98Hz, auto, auto, bitdepth, 8, cm, auto"
        "HDMI-A-1, disable"
      ];
    };
  };

  home.username = "fveracoechea";
  home.homeDirectory = "/home/fveracoechea";

  home.file.".face".source = ../../assets/face.jpg;
  home.file.".face.icon".source = ../../assets/face.jpg;

  home.packages = with pkgs; [
    slack
    vesktop
    google-chrome
    kooha
    python3
    nurl
    watchman
    ripgrep
    jq
    just
    postman
    wireguard-tools
    lutgen
    beekeeper-studio
    dotfilesPkgs.dev-manager-desktop
    dotfilesPkgs.railway
    openlinkhub
    zettlr
    agent-browser
    tiny-rdm
    obs-studio

    (writers.writeBashBin "set-screen-share-resolution" ''
      hyprctl keyword monitor "DP-1, 2560x1440@120.00Hz, auto, auto, vrr, 3, bitdepth, 8, cm, auto"
    '')

    (writers.writeBashBin "unset-screen-share-resolution" ''
      hyprctl keyword monitor "DP-1, 5120x1440@119.98Hz, auto, auto, bitdepth, 8, cm, auto"
    '')
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = ["config.local"];
    settings = {
      homelab = {
        HostName = "10.0.0.2";
        User = "fveracoechea";
        IdentityFile = "~/.ssh/fveracoechea";
      };

      "github.com" = {
        User = "git";
        IdentitiesOnly = "yes";
        IdentityFile = "~/.ssh/id_github_hypr";
      };
    };
  };

  # DO NOT CHANGE
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
