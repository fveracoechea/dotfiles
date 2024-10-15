{
  programs.git = {
    enable = true;
    userEmail = "veracoecheafrancisco@gmail.com";
    userName = "Francisco Veracoechea";
    extraConfig = {
      core = {
        editor = "nvim";
        sshCommand = "ssh -i ~/.ssh/id_github";
      };
      pull = {
        rebase = true;
      };
      rebase = {
        autosquash = true;
      };
    };
  };
}
