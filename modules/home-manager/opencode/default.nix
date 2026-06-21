{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  options.dotfiles.opencode.enable = lib.mkEnableOption "opencode desktop CLI";

  config = lib.mkIf config.dotfiles.opencode.enable {
    home.packages = with pkgs; [
      lsof
      opencode-desktop
      mcp-nixos
    ];

    home.sessionVariables = {
      OPENCODE_ENABLE_EXA = "true";
      OPENCODE_EXPERIMENTAL_LSP_TOOL = "true";
    };

    programs.opencode = {
      enable = true;

      commands = {
        create-pr = ./command/create-pr.md;
      };

      tui = {
        theme = "system";
      };

      settings = {
        autoupdate = false;

        skills.paths = [
          "${inputs.hunk}/skills"
        ];

        mcp = {
          grep = {
            enabled = true;
            type = "remote";
            url = "https://mcp.grep.app";
          };
        };
      };
    };
  };
}
