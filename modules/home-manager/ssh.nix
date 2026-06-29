{
  lib,
  config,
  ...
}: {
  options.dotfiles.ssh.enable = lib.mkEnableOption "SSH client config";

  config = lib.mkIf config.dotfiles.ssh.enable {
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
  };
}
