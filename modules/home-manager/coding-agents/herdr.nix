{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.dotfiles.coding-agents.enable {
    programs.herdr = {
      enable = true;
      settings = {
        keys = {
          prefix = "ctrl+b";
          detatch = "prefix+d";
        };

        theme = {
          auto_switch = true;
          dark_name = "catppuccin";
          light_name = "catppuccin-latte";
          name = "catppuccin";
        };
      };
    };
  };
}
