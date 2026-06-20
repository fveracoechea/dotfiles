{
  inputs,
  pkgs,
  customPkgs,
  ...
}: {
  imports = [
    ../../modules/home-manager/default.nix
    inputs.neovim-config.homeManagerModules.default
  ];

  dotfiles.bat.enable = true;

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
    customPkgs.dev-manager-desktop
    customPkgs.railway
    openlinkhub
    docker-compose
    zettlr
    agent-browser
    tiny-rdm
    obs-studio
  ];

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.05";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
