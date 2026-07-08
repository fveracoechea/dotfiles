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

        # permission.external_directory."~/OPINIONS.md" = "allow";
        permission."*" = "allow";

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

        lsp = {
          nixd = {
            command = ["nixd"];
            extensions = [".nix"];
          };
          lua_ls = {
            command = ["lua-language-server"];
            extensions = [".lua"];
          };
          biome = {
            command = ["biome" "lsp-proxy"];
            extensions = [
              ".js"
              ".jsx"
              ".ts"
              ".tsx"
              ".json"
              ".jsonc"
              ".css"
              ".html"
              ".graphql"
              ".vue"
              ".svelte"
              ".astro"
            ];
          };
          stylelint = {
            command = ["stylelint-language-server" "--stdio"];
            extensions = [
              ".css"
              ".scss"
              ".less"
              ".html"
              ".vue"
              ".astro"
            ];
          };
        };
      };
    };
  };
}
