{pkgs, ...}: {
  imports = [
    ../../modules/home-manager/default.nix
  ];

  dotfiles = {
    shell.enable = true;
    volta.enable = true;
    ghostty.enable = true;
    fonts.enable = true;
    karabiner.enable = true;
    neovim.enable = true;
    # aerospace.enable = true;
    coding-agents.enable = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "github.com" = {
        AddKeysToAgent = "yes";
        IdentityFile = "~/.ssh/id_github_hypr";
        UseKeychain = "yes";
      };
    };
  };

  home.packages = with pkgs; [
    watchman
    ripgrep
    wget
    just
    wireguard-tools
    agent-browser
    glab
    redis
    lazydocker
  ];

  # DO NOT CHANGE
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
