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
    };
  };
}
