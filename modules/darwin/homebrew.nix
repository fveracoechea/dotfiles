{
  lib,
  config,
  ...
}: {
  options.dotfiles.homebrew.enable = lib.mkEnableOption "Homebrew casks and formulae";

  config = lib.mkIf config.dotfiles.homebrew.enable {
    # Homebrew does not add its bin directory to the PATH by itself.
    environment.systemPath = ["${config.homebrew.prefix}/bin"];

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
        "handy"
      ];
      brews = [
        "maven"
        "azure-cli"
        "node@22"
      ];
    };
  };
}
