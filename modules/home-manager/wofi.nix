{lib, ...}: {
  programs.wofi = {
    enable = true;
    settings = {
      width = 450;
      no_actions = true;
    };
    style = lib.fileContents ../../config/wofi/catppuccin.css;
  };

  stylix.targets.wofi.enable = false;
}
