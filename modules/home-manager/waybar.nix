{lib, ...}: {
  programs.waybar = {
    enable = true;

    style =
      # css
      ''
        ${lib.fileContents ../../config/waybar/catppuccin.css}

        ${lib.fileContents ../../config/waybar/styles.css}
      '';
  };
}
