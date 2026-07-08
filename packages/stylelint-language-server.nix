{
  pkgs,
}: let
  lockFile = ./stylelint-language-server-lock.json;
in
  pkgs.buildNpmPackage {
    pname = "stylelint-language-server";
    version = "1.1.1";

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@stylelint/language-server/-/language-server-1.1.1.tgz";
      hash = "sha256-l+7GKyWhrEvJ3boylbQBAZziwzbZoQdxWi9np5vaTf4=";
    };

    postPatch = ''
      cp ${lockFile} package-lock.json
    '';

    npmDepsHash = "sha256-yMn596qq+PtYiaSCrUl05mQu3Zyl51a7d7S4GkuKjzY=";
    dontNpmBuild = true;
  }
