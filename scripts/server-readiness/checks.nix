{ pkgs, manifests }:
let
  fixtures = pkgs.writeText "server-readiness-manifests.json" (
    builtins.unsafeDiscardStringContext (builtins.toJSON manifests)
  );
in
pkgs.runCommand "server-readiness-tests"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.just
    ];
  }
  ''
    cp -r ${../..} source
    chmod -R u+w source
    cd source
    READINESS_MANIFESTS=${fixtures} python3 scripts/server-readiness/gate_test.py
    python3 scripts/server-readiness/mutation_test.py
    touch "$out"
  ''
