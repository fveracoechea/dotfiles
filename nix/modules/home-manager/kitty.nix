{...}: {
  programs.kitty = {
    enable = true;
    theme = "Catppuccin-Mocha";
    shellIntegration.enableZshIntegration = true;

    settings = {
      bold_font = "FiraCode Nerd Font Bold";
      italic_font = "FiraCode Nerd Font Italic";
      bold_italic_font = "FiraCode Nerd Font Bold Italic";
      # fix title bar
      # linux_display_server = "x11";
      window_padding_width = 2;
    };
  };
}
