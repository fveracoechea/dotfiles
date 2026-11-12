{
  codingAgentSources,
  lib,
  config,
  pkgs,
  codingAgentMcpPackage,
  codingAgentPackages,
  ...
}: {
  config = lib.mkIf config.dotfiles.coding-agents.enable {
    xdg.configFile."opencode/plugins/operator.ts".source = "${codingAgentPackages.operator}/share/opencode/plugins/operator.ts";
    xdg.configFile."opencode/agents/super.md".source = "${codingAgentSources.operator-agents}/agents/opencode/super.md";
    xdg.configFile."opencode/agents/worker.md".source = "${codingAgentSources.operator-agents}/agents/opencode/worker.md";

    home.packages = with pkgs; [
      lsof
      # Latest depends on broken fastmcp-slim. Return when its MCP 2 support is fixed.
      codingAgentMcpPackage
    ];

    programs.opencode = {
      enable = true;

      context = "${codingAgentSources.operator}/agents/AGENTS.md";

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

      skills =
        lib.genAttrs codingAgentPackages.operator.skills (name: "${codingAgentPackages.operator}/share/skills/operator/${name}")
        // {
          herdr = "${codingAgentSources.herdr}/skills/herdr";
          hunk-review = "${codingAgentSources.hunk}/packages/hunk/skills/hunk-review";
        };

      settings = {
        update = "disable";
        model = lib.mkDefault "openai/gpt-6.1-sol";

        mcp.servers.nix-mcp = {
          type = "local";
          command = [(lib.getExe codingAgentMcpPackage)];
        };

        compaction = {
          buffer = "25%";
          keep.tokens = 20000;
        };

        agents = {
          plan.disabled = true;
          build.model = "openai/gpt-6.1-sol#high";
          super.model = "openai/gpt-6.1-sol#high";
          worker.model = "openai/gpt-6.1-sol#medium";
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
            settings.compaction.type = "native";
            models."gpt-6.1-sol" = {
              settings.reasoningEffort = "high";
              variants = [
                {
                  id = "medium";
                  settings.reasoningEffort = "medium";
                }
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
