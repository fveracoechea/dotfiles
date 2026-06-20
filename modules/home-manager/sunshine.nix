{lib, config, ...}: {
  options.dotfiles.sunshine.enable = lib.mkEnableOption "Sunshine game streaming config";

  config = lib.mkIf config.dotfiles.sunshine.enable {
    xdg.configFile."sunshine/apps.json".text = builtins.toJSON {
      env = {
        "PATH" = "$(PATH):$(HOME)/.local/bin";
      };
      apps = [
        {
          name = "Desktop";
          image-path = "desktop.png";
          prep-cmd = [
            {
              do = "set-screen-share-resolution";
              undo = "unset-screen-share-resolution";
            }
          ];
        }
        {
          name = "Steam Big Picture";
          image-path = "steam.png";
          auto-detach = "true";
        }
      ];
    };
  };
}
