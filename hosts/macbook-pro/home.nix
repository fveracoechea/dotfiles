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
    spotify.enable = true;
    aerospace.enable = true;
    coding-agents.enable = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "github.com" = {
        User = "git";
        UseKeychain = "yes";
        AddKeysToAgent = "yes";
        IdentitiesOnly = "yes";
        IdentityFile = "~/.ssh/id_github";
      };
    };
  };

  home.packages = with pkgs; [
    redis
    lazydocker
    handy
  ];

  # DO NOT CHANGE
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
