{
  vimUtils,
  fetchFromGitHub,
}:
vimUtils.buildVimPlugin {
  pname = "herdr-nvim";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "ChmaraX";
    repo = "herdr-nvim";
    rev = "0450dc7b4c40c986052541c00dba5cdcd1be7ac6";
    hash = "sha256-KpcNuX0I0N5oFzjsLpZV59SYVzaNO8j1+kDtBG2bK5Y=";
  };
}
