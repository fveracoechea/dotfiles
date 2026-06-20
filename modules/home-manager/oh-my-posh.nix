{
  lib,
  config,
  ...
}: let
  p = config.dotfiles.palette;
in {
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
          foreground = p.text;
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
                powerline_symbol = "";
                leading_diamond = "";
                foreground = p.text;
                background = p.mantle;
                template = "{{ .Icon }} ";
                foreground_templates = [
                  "{{if gt .Code 0}}${p.red}{{end}}"
                  "{{if eq .Code 0}}${p.text}{{end}}"
                ];
              }
              {
                type = "session";
                style = "powerline";
                powerline_symbol = "";
                foreground = p.blue;
                background = p.mantle;
                template = "{{ .UserName }}{{ if .SSHSession }}   {{ .HostName }}{{ end }}";
              }
              {
                type = "path";
                style = "powerline";
                powerline_symbol = "";
                foreground = p.pink;
                background = p.mantle;
                template = " {{ .Path }} ";
                properties = {
                  home_icon = "~";
                  style = "agnoster_full";
                };
              }
              {
                type = "executiontime";
                style = "powerline";
                powerline_symbol = "";
                foreground = p.lavender;
                background = p.mantle;
                template = " {{ .FormattedMs }} ";
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
                foreground = p.text;
              }
            ];
          }
        ];
      };
    };
  };
}
