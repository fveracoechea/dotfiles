{
  lib,
  config,
  inputs,
  ...
}: {
  config = lib.mkIf config.dotfiles.coding-agents.enable {
    programs.claude-code = {
      enable = true;

      context = ./AGENTS.md;

      settings = {
        theme = "dark-ansi";

        statusLine = {
          type = "command";
          command = "${./claude-statusline.sh}";
        };
      };

      skills = {
        hunk-review = "${inputs.hunk}/skills/hunk-review/SKILL.md";
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
        biome = {
          command = "biome";
          args = ["lsp-proxy"];
          extensionToLanguage = {
            ".js" = "javascript";
            ".jsx" = "javascriptreact";
            ".ts" = "typescript";
            ".tsx" = "typescriptreact";
            ".json" = "json";
            ".jsonc" = "jsonc";
            ".css" = "css";
            ".html" = "html";
            ".graphql" = "graphql";
            ".vue" = "vue";
            ".svelte" = "svelte";
            ".astro" = "astro";
          };
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
