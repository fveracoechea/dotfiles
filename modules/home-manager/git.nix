{
  programs.git = {
    enable = true;
    userEmail = "veracoecheafrancisco@gmail.com";
    userName = "Francisco Veracoechea";
    extraConfig = {
      pull = {
        rebase = true;
      };
    };
  };
}
