{lib, ...}: {
  programs.waybar = {
    enable = true;

    style =
      lib.mkForce
      # css
      ''
        ${lib.fileContents ../../config/waybar/catppuccin.css}

        ${lib.fileContents ../../config/waybar/styles.css}
      '';
  };
}
