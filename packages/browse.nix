{
  fetchurl,
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "browse";
  version = "0.1.5";

  src = fetchurl {
    url = "https://anoma.ly/release/browse/files/47b34fd98912c09728d5385ef3aa712f86f5fe3dfee86ead38ed645a29d95d19/opencode-browse-linux-x64-musl-${finalAttrs.version}.tgz";
    hash = "sha256-R7NP2YkSwJco1The86pxL4b1/j3+6G6tOO1kWinZXRk=";
  };

  sourceRoot = "package";
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/browse "$out/bin/browse"
    install -Dm644 LICENSE "$out/share/licenses/browse/LICENSE"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test "$("$out/bin/browse" --version)" = "${finalAttrs.version}"
    "$out/bin/browse" tools > /dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "MCP server and relay for controlling a real Chromium browser";
    homepage = "https://github.com/anomalyco/browse";
    license = lib.licenses.mit;
    mainProgram = "browse";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
