{
  lib,
  config,
  codingAgentSources,
  ...
}: {
  config = lib.mkIf config.dotfiles.coding-agents.enable {
    programs.claude-code = {
      enable = true;

      context = ./AGENTS.md;

      settings = {
        theme = "dark-ansi";

        model = "claude-opus-5";
        effortLevel = "high";

        statusLine = {
          type = "command";
          command = "${./claude-statusline.sh}";
        };

        permissions = {
          allow = [
            "Bash(*)"
            "Read(*)"
            "Edit(*)"
            "Write(*)"
            "Glob(*)"
            "Grep(*)"
            "WebFetch"
            "WebSearch"
            "mcp__plugin_figma_figma"
            "Skill(figma:*)"
          ];
          deny = [
            "EnterPlanMode"
            "ExitPlanMode"
            "DesignSync"
            "NotebookEdit"
            "PushNotification"
            "RemoteTrigger"
            "ReportFindings"
            "ScheduleWakeup"
            "AskUserQuestion"
            "CronCreate"
            "CronDelete"
            "CronList"
          ];
        };

        disableBundledSkills = true;
        disableWorkflows = true;
        disableRemoteControl = true;
        disableClaudeAiConnectors = true;
        disableArtifact = true;
      };

      skills = {
        herdr = "${codingAgentSources.herdr}/skills/herdr";
        hunk-review = "${codingAgentSources.hunk}/skills/hunk-review";
        babysit-pr = ../../../.agents/skills/babysit-pr;
        frontend-design = ../../../.agents/skills/frontend-design;
      };

      plugins = {
        figma = codingAgentSources.figma-plugin;
      };

      lspServers = {
        nixd = {
          command = "nixd";
          extensionToLanguage = {".nix" = "nix";};
        };
        lua_ls = {
          command = "lua-language-server";
          extensionToLanguage = {".lua" = "lua";};
        };
        stylelint = {
          command = "stylelint-language-server";
          args = ["--stdio"];
          extensionToLanguage = {
            ".css" = "css";
            ".scss" = "scss";
            ".less" = "less";
            ".html" = "html";
            ".vue" = "vue";
            ".astro" = "astro";
          };
        };
        oxlint = {
          command = "oxlint";
          args = ["--lsp"];
          extensionToLanguage = {
            ".js" = "javascript";
            ".jsx" = "javascriptreact";
            ".ts" = "typescript";
            ".tsx" = "typescriptreact";
            ".vue" = "vue";
            ".svelte" = "svelte";
            ".astro" = "astro";
          };
        };
        oxfmt = {
          command = "oxfmt";
          args = ["--lsp"];
          extensionToLanguage = {
            ".js" = "javascript";
            ".jsx" = "javascriptreact";
            ".ts" = "typescript";
            ".tsx" = "typescriptreact";
            ".toml" = "toml";
            ".json" = "json";
            ".jsonc" = "jsonc";
            ".json5" = "json5";
            ".yaml" = "yaml";
            ".yml" = "yaml";
            ".html" = "html";
            ".vue" = "vue";
            ".handlebars" = "handlebars";
            ".hbs" = "handlebars";
            ".css" = "css";
            ".scss" = "scss";
            ".less" = "less";
            ".graphql" = "graphql";
            ".md" = "markdown";
          };
        };
      };
    };
  };
}
