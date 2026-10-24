{
  lib,
  config,
  dotfilesPkgs,
  codingAgentSources,
  ...
}: let
  # Declarative equivalent of `herdr integration install opencode`,
  # which cannot patch the read-only configs home-manager writes.
  assets = "${codingAgentSources.herdr}/src/integration/assets";
in {
  config = lib.mkIf config.dotfiles.coding-agents.enable {
    programs.herdr = {
      enable = true;
      package = dotfilesPkgs.herdr;
      settings = {
        onboarding = false;

        keys = {
          prefix = "ctrl+b";
          detach = "prefix+d";
          goto = "prefix+s";
          settings = "prefix+g";
          navigate_workspace_down = "j";
          navigate_workspace_up = "k";
        };

        theme = {
          auto_switch = false;
          name = "catppuccin";
        };

        ui = {
          sidebar_width = 32;
          agent_panel_sort = "spaces";
          show_agent_labels_on_pane_borders = true;
        };
      };
    };

    programs.opencode.cli.plugins = ["./herdr-opencode"];

    xdg.configFile."opencode/herdr-opencode/tui.js".source = "${assets}/opencode/herdr-tui-session.js";
  };
}
