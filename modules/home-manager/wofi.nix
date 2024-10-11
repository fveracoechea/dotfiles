{lib, ...}: {
  programs.wofi = {
    enable = true;
    settings = {
      width = 600;
      no_actions = true;
    };
    style = lib.fileContents ../../config/wofi/catppuccin.css;
  };

  stylix.targets.wofi.enable = false;
}
