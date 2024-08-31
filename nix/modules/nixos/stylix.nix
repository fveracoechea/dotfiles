{pkgs, ...}: let
  firaSans = {
    package = pkgs.fira-sans;
    name = "Fira Sans";
  };
  firaCode = {
    package = pkgs.fira-code-nerdfont;
    name = "FiraCode Nerd Font";
  };
in {
  stylix = {
    enable = true;
    autoEnable = true;
    image = ../../../wallpapers/evening-sky.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    polarity = "dark";

    cursor = {
      name = "catppuccin-mocha-dark-cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
      size = 34;
    };

    fonts = {
      serif = firaSans;
      sansSerif = firaSans;
      monospace = firaCode;
      emoji = firaCode;
    };

    targets.chromium.enable = false;
  };
}
