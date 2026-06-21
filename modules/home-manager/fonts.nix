{lib, config, pkgs, ...}: {
  options.dotfiles.fonts.enable = lib.mkEnableOption "font packages and fontconfig";

  config = lib.mkIf config.dotfiles.fonts.enable {
    home.packages = with pkgs; [
      inter
      fira-sans
      open-sans
      geist-font
      ubuntu-sans

      nerd-fonts.hack
      nerd-fonts.fira-code
      nerd-fonts.ubuntu-sans
      nerd-fonts.jetbrains-mono
    ];

    fonts.fontconfig = {
      enable = true;
      antialiasing = true;
      defaultFonts = {
        serif = ["Inter"];
        sansSerif = ["Inter"];
        monospace = ["JetBrainsMono Nerd Font"];
        emoji = ["JetBrainsMono Nerd Font"];
      };
    };
  };
}
