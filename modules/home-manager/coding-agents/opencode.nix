{
  codingAgentSources,
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

      skills = {
        herdr = "${codingAgentSources.herdr}/skills/herdr";
        hunk-review = "${codingAgentSources.hunk}/packages/hunk/skills/hunk-review";
        babysit-pr = ../../../.agents/skills/babysit-pr;
        frontend-design = ../../../.agents/skills/frontend-design;
      };

      settings = {
        autoupdate = false;
        model = "openrouter/z-ai/glm-5.3-flash";

        agent = {
          build = {
            model = "openrouter/z-ai/glm-5.3-flash";
            variant = "high";
          };
        };

        # permission.external_directory."~/OPINIONS.md" = "allow";
        permission."*" = "allow";

        provider = {
          openrouter = {
            models."z-ai/glm-5.3-flash" = {
              options.reasoning.effort = "high";
              variants.high.reasoning.effort = "high";
            };

            options = {
              extraBody = {
                provider = {
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
          };
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
          qmlls = {
            command = ["qmlls"];
            extensions = [".qml"];
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
          oxlint = {
            command = ["oxlint" "--lsp"];
            extensions = [
              ".js"
              ".jsx"
              ".ts"
              ".tsx"
              ".vue"
              ".svelte"
              ".astro"
            ];
          };
          oxfmt = {
            command = ["oxfmt" "--lsp"];
            extensions = [
              ".js"
              ".jsx"
              ".ts"
              ".tsx"
              ".toml"
              ".json"
              ".jsonc"
              ".json5"
              ".yaml"
              ".yml"
              ".html"
              ".vue"
              ".handlebars"
              ".hbs"
              ".css"
              ".scss"
              ".less"
              ".graphql"
              ".md"
            ];
          };
        };
      };
    };
  };
}
