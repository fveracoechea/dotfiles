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
          command = "input=$(cat); model=$(echo \"$input\" | jq -r '.model.display_name'); used=$(echo \"$input\" | jq -r '.context_window.used_percentage // empty'); if [ -n \"$used\" ]; then printf \"%s | ctx: %.0f%% used\" \"$model\" \"$used\"; else printf \"%s\" \"$model\"; fi";
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
      };
    };
  };
}
