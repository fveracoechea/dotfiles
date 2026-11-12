{ ... }: {
  dotfiles = {
    shell.enable = true;
    neovim.enable = true;
    fonts.enable = true;
    coding-agents.enable = true;
  };

  home.username = "fveracoechea";
  home.homeDirectory = "/home/fveracoechea";
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."github.com" = {
      IdentityFile = "~/.ssh/github_id";
      IdentitiesOnly = "yes";
      User = "git";
    };
  };

  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
}
