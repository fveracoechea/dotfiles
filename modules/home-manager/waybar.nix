{lib, ...}: {
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        spacing = 8;
        modules-left = ["clock"];
        modules-right = ["network" "cpu" "memory"];
        modules-center = ["clock"];
      };
    };

    style = ''
      ${lib.fileContents ../../config/waybar/catppuccin.css}
      ${lib.fileContents ../../config/waybar/styles.css}
    '';
  };

  stylix.targets.waybar.enable = false;
}
