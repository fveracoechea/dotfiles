{pkgs, ...}: {
  home.packages = [
    pkgs.lsof
    pkgs.opencode-desktop
  ];

  home.sessionVariables = {
    OPENCODE_ENABLE_EXA = "true";
    OPENCODE_EXPERIMENTAL_LSP_TOOL = "true";
  };

  programs.opencode = {
    enable = true;

    commands = {
      create-pr = ./command/create-pr.md;
    };

    tui = {
      theme = "system";
    };

    settings = {
      autoupdate = false;

      mcp = {
        grep = {
          enabled = true;
          type = "remote";
          url = "https://mcp.grep.app";
        };
      };
    };
  };
}
