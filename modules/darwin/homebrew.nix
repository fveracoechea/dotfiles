{
  lib,
  config,
  ...
}: {
  options.dotfiles.homebrew.enable = lib.mkEnableOption "Homebrew casks and formulae";

  config = lib.mkIf config.dotfiles.homebrew.enable {
    # Homebrew - needs to be manually installed.
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
        upgrade = true;
      };
      casks = [
        "docker-desktop"
        "karabiner-elements"
        "beekeeper-studio"
        "google-chrome"
        "microsoft-teams"
        "microsoft-outlook"
        "slack"
        "figma"
        "postman"
      ];
      brews = [
        "pulumi"
        "awscli"
      ];
    };
  };
}
