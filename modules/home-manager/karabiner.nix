{
  lib,
  config,
  ...
}: {
  options.dotfiles.karabiner.enable = lib.mkEnableOption "Karabiner-Elements complex modifications";

  config = lib.mkIf config.dotfiles.karabiner.enable {
    # enable xdg config directory by default
    xdg.enable = lib.mkDefault true;

    # Karabiner-Elements is installed by homebrew
    xdg.configFile."karabiner/assets/complex_modifications/nix.json".text = builtins.toJSON {
      title = "CapsLock modifier - Nix managed";
      rules = [
        {
          description = ''
            Change caps_lock to left_control if pressed with other keys,
            change caps_lock to escape if pressed alone.
          '';
          manipulators = [
            {
              type = "basic";
              from = {
                key_code = "caps_lock";
                modifiers = {optional = ["any"];};
              };
              to = [
                {key_code = "left_control";}
              ];
              to_if_alone = [
                {key_code = "escape";}
              ];
              conditions = [
                {
                  type = "device_if";
                  identifiers = [{is_built_in_keyboard = true;}];
                }
              ];
            }
          ];
        }
      ];
    };
  };
}
