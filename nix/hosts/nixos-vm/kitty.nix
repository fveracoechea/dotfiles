{...}: {
  programs.kitty = {
    enable = true;
    theme = "Catppuccin-Mocha";
    font = {
      name = "FiraCode Nerd Font";
      size = "12";
    };

    settings = {
      bold_font = "FiraCode Nerd Font Bold";
      italic_font = "FiraCode Nerd Font Italic";
      bold_italic_font = "FiraCode Nerd Font Bold Italic";

      linux_display_server = "x11";

      window_padding_width = 2;

      background_opacity = 0.95;
    };

    shellIntegration.enableZshIntegration = true;
  };
}
