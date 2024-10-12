{
  pkgs,
  lib,
  ...
}: let
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
    image = ../../config/wallpapers/aerrotltt4ud1.jpeg;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    polarity = "dark";

    opacity = {
      terminal = 0.9;
      desktop = 0.9;
    };

    cursor = {
      name = "catppuccin-mocha-dark-cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
      size = 38;
    };

    fonts = {
      serif = firaSans;
      sansSerif = firaSans;
      monospace = firaCode;
      emoji = firaCode;
    };

    targets.chromium.enable = lib.mkForce false;
  };
}
