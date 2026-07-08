{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf config.dotfiles.coding-agents.enable {
    home.packages = with pkgs; [
      lsof
      mcp-nixos
    ];

    home.sessionVariables = {
      OPENCODE_ENABLE_EXA = "true";
      OPENCODE_EXPERIMENTAL_LSP_TOOL = "true";
    };

    programs.opencode = {
      enable = true;

      context = ./AGENTS.md;

      commands = {
        create-pr = ./command/create-pr.md;
      };

      tui = {
        theme = "system";
      };

      settings = {
        autoupdate = false;

        skills = {
          hunk-review = "${inputs.hunk}/skills/hunk-review/SKILL.md";
        };

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
