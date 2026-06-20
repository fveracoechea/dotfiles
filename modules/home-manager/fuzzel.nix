{
  lib,
  config,
  ...
}: let
  p = config.dotfiles.palette;
  toHex = color: "${lib.substring 1 6 (lib.strings.toLower color)}ff";
in {
  options.dotfiles.fuzzel.enable = lib.mkEnableOption "fuzzel (Wayland app launcher)";

  config = lib.mkIf config.dotfiles.fuzzel.enable {
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          width = 38;
          match-mode = "fzf";
          match-counter = "yes";
          layer = "overlay";
          icon-theme = "Papirus-Dark";
          icons-enabled = "yes";
          horizontal-pad = 20;
          vertical-pad = 12;
          line-height = 22;
          prompt = ''"❯  "'';
          placeholder = "Apps";
          font = "Fira Sans:style=Regular:size=12";
        };

        border = {
          width = 3;
          radius = 8;
        };

        key-bindings = {
          delete-line-forward = "none";
          next = "Control+n";
          prev = "Control+p";
        };

        colors = {
          background = toHex p.base;
          text = toHex p.text;
          prompt = toHex p.subtext1;
          placeholder = toHex p.overlay1;
          input = toHex p.text;
          match = toHex p.blue;
          selection = toHex p.surface2;
          selection-text = toHex p.text;
          selection-match = toHex p.blue;
          counter = toHex p.overlay1;
          border = toHex p.blue;
        };
      };
    };
  };
}
