{pkgs, ...}: {
  home.packages = [pkgs.kitty];

  programs.kitty = {
    enable = true;
    theme = "Catppuccin-Mocha";
    shellIntegration.enableZshIntegration = true;

    settings = {
      bold_font = "FiraCode Nerd Font Bold";
      italic_font = "FiraCode Nerd Font Italic";
      bold_italic_font = "FiraCode Nerd Font Bold Italic";
      window_padding_width = 2;
    };
  };
}
