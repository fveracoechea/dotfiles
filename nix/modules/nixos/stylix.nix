{pkgs, ...}: let
  firaSans = {
    package = pkgs.fira-sans;
    name = "Fira Sans";
  };
  firaCode = {
    package = pkgs.fira-code-nerdfonts;
    name = "Fira Code";
  };
in {
  stylix = {
    enable = true;
    autoEnable = true;
    image = ../../../wallpapers/mountains.jpg;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    polarity = "dark";

    fonts = {
      serif = firaSans;
      sansSerif = firaSans;
      monospace = firaCode;
      emoji = firaCode;
    };
  };
}
