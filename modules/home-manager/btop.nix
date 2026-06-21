{lib, config, ...}: {
  options.dotfiles.btop.enable = lib.mkEnableOption "btop system monitor";

  config = lib.mkIf config.dotfiles.btop.enable {
    programs.btop = {
      enable = true;
      settings = {
        theme_background = false;
        truecolor = true;
        vim_keys = true;
        rounded_corners = true;
        graph_symbol = "braille";
        proc_gradient = true;
        temp_scale = "celsius";
      };
    };
  };
}
