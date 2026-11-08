{
  lib,
  config,
  pkgs,
  ...
}: {
  options.dotfiles.ghostty.enable = lib.mkEnableOption "Ghostty terminal emulator";

  config = lib.mkIf config.dotfiles.ghostty.enable {
    programs.ghostty = {
      enable = true;
      enableZshIntegration = true;
      package = pkgs.ghostty;

      settings = {
        theme = "Catppuccin Mocha";
        shell-integration = "zsh";

        background-opacity = 0.8;
        background-blur = 80;

        window-padding-color = "background";
        window-padding-x = 6;
        window-padding-y = 6;
        window-decoration = "auto";
        font-size = 13;

        font-family-bold = "JetBrainsMono Nerd Font Bold";
        font-family-italic = "JetBrainsMono Nerd Font Italic";
        font-family-bold-italic = "JetBrainsMono Nerd Font Italic Bold";
      };
    };
  };
}
