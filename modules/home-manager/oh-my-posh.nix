{
  lib,
  config,
  customUtils,
  ...
}: {
  options.dotfiles.oh-my-posh.enable = lib.mkEnableOption "oh-my-posh (shell prompt)";

  config = lib.mkIf config.dotfiles.oh-my-posh.enable {
    programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      version = 3;
      final_space = true;
      enable_cursor_positioning = true;

      secondary_prompt = {
        foreground = customUtils.catppuccin.text;
        background = "transparent";
        template = "❯❯ ";
      };

      blocks = [
        {
          type = "prompt";
          alignment = "left";
          newline = true;
          segments = [
            {
              type = "text";
              style = "plain";
              background = "transparent";
              template = "\n";
            }
            {
              type = "os";
              style = "diamond";
              powerline_symbol = "";
              leading_diamond = "";
              foreground = customUtils.catppuccin.text;
              background = customUtils.catppuccin.mantle;
              template = "{{ .Icon }} ";
              foreground_templates = [
                "{{if gt .Code 0}}${customUtils.catppuccin.red}{{end}}"
                "{{if eq .Code 0}}${customUtils.catppuccin.text}{{end}}"
              ];
            }
            {
              type = "session";
              style = "powerline";
              powerline_symbol = "";
              foreground = customUtils.catppuccin.blue;
              background = customUtils.catppuccin.mantle;
              template = "{{ .UserName }}{{ if .SSHSession }}    {{ .HostName }}{{ end }}";
            }
            {
              type = "path";
              style = "powerline";
              powerline_symbol = "";
              foreground = customUtils.catppuccin.pink;
              background = customUtils.catppuccin.mantle;
              template = " {{ .Path }} ";
              properties = {
                home_icon = "~";
                style = "agnoster_full";
              };
            }
            {
              type = "executiontime";
              style = "powerline";
              powerline_symbol = "";
              foreground = customUtils.catppuccin.lavender;
              background = customUtils.catppuccin.mantle;
              template = " {{ .FormattedMs }} ";
              properties = {
                style = "austin";
                always_enabled = true;
              };
            }
          ];
        }
        {
          type = "prompt";
          alignment = "left";
          newline = true;
          segments = [
            {
              type = "text";
              style = "plain";
              template = "❯";
              background = "transparent";
              foreground = customUtils.catppuccin.text;
            }
          ];
        }
      ];
    };
  };
};
}
