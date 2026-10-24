{
  codingAgentSources,
  lib,
  config,
  pkgs,
  pkgs-stable,
  ...
}: {
  config = lib.mkIf config.dotfiles.coding-agents.enable {
    home.packages = with pkgs; [
      lsof
      # Latest depends on broken fastmcp-slim. Return when its MCP 2 support is fixed.
      pkgs-stable.mcp-nixos
    ];

    programs.opencode = {
      enable = true;

      context = ./AGENTS.md;

      cli = {
        theme = {
          name = "system";
          mode = "system";
        };
        session = {
          sidebar = "auto";
          scrollbar = false;
          thinking = "show";
        };
        diffs.wrap = "word";
        animations = true;
      };

      validateFiles = {
        config = true;
        cli = true;
      };

      skills = {
        herdr = "${codingAgentSources.herdr}/skills/herdr";
        hunk-review = "${codingAgentSources.hunk}/packages/hunk/skills/hunk-review";
        no-slop = "${codingAgentSources.operator}/skills/no-slop";
        pr-review = "${codingAgentSources.operator}/skills/pr-review";
        frontend-design = ../../../.agents/skills/frontend-design;
      };

      settings = {
        update = "disable";
        model = "openai/gpt-6.1-sol";

        agents = {
          build = {
            model = "openai/gpt-6.1-sol#high";
          };
        };

        permissions = [
          {
            action = "*";
            resource = "*";
            effect = "allow";
          }
        ];

        experimental.todo = true;
        websearch.provider = "exa";

        providers = {
          openai = {
            models."gpt-6.1-sol" = {
              settings.reasoningEffort = "high";
              variants = [
                {
                  id = "high";
                  settings.reasoningEffort = "high";
                }
              ];
            };
          };

          openrouter = {
            models."z-ai/glm-5.3-flash" = {
              settings.reasoning.effort = "high";
              variants = [
                {
                  id = "high";
                  settings.reasoning.effort = "high";
                }
              ];
            };

            body.provider = {
              sort = "throughput";
              only = [
                "baseten"
                "novita"
                "fireworks"
              ];
              allow_fallbacks = true;
              data_collection = "deny";
              zdr = true;
            };
          };
        };

        lsp = {
          nixd = {
            command = ["nixd"];
            extensions = [".nix"];
          };
          typescript = {
            command = ["typescript-language-server" "--stdio"];
            extensions = [
              ".js"
              ".jsx"
              ".ts"
              ".tsx"
              ".mjs"
              ".cjs"
              ".mts"
              ".cts"
            ];
          };
        };
      };
    };
  };
}
