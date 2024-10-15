{
  programs.git = {
    enable = true;
    userEmail = "veracoecheafrancisco@gmail.com";
    userName = "Francisco Veracoechea";
    extraConfig = {
      core = {
        sshCommand = "ssh -i ~/.ssh/id_github";
      };
      pull = {
        rebase = true;
      };
    };
  };
}
