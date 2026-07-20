{
  lib,
  config,
  ...
}: {
  options.dotfiles.homebrew.enable = lib.mkEnableOption "Homebrew casks and formulae";

  config = lib.mkIf config.dotfiles.homebrew.enable {
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
        "google-chrome"
        "slack"
        "figma"
        "postman"
        "zoom"
        "openvpn-connect"
      ];
      brews = [];
    };
  };
}
