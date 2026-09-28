{
  fetchurl,
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "railway";
  version = "5.62.1";

  src = fetchurl {
    url = "https://github.com/railwayapp/cli/releases/download/v${finalAttrs.version}/railway-v${finalAttrs.version}-x86_64-unknown-linux-musl.tar.gz";
    hash = "sha256-LQTwg2C0xV9SueRY4EmH7JiCYfFtL7T8TnstQ61KbLI=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    tar -xzf "$src" -C "$out/bin"
    chmod +x "$out/bin/railway"
    runHook postInstall
  '';

  meta = {
    description = "Railway.app CLI";
    homepage = "https://github.com/railwayapp/cli";
    license = lib.licenses.mit;
    mainProgram = "railway";
    platforms = ["x86_64-linux"];
  };
})
