{
  lib,
  pkgs,
  pkgs-stable,
  inputs,
  system,
}: let
  flake = inputs.self;

  hyprlandCheckDir = flake.outPath + "/checks/hyprland";
  productionConfigDir = flake.outPath + "/config/hypr";

  # The gate runs on Lua 5.5, the interpreter version Hyprland 0.55.4 embeds
  # (CMakeLists.txt asks pkg-config for lua55/lua5.5).
  lua55 = pkgs.lua5_5;

  # The Release Channel owns the compositor (ADR-0007), so the parser gate
  # uses the System-owned Hyprland, pinned at 0.55.4 in nixos-26.05.
  hyprland = pkgs-stable.hyprland;

  luaTest = name: script: extraEnv:
    pkgs.runCommand name ({
      nativeBuildInputs = [lua55];
      repoRoot = flake.outPath;
    } // extraEnv) ''
      set -euo pipefail
      export HOME=$TMPDIR
      lua ${flake.outPath}/checks/hyprland/${script} "$repoRoot"
      touch "$out"
    '';

  # Formatting, lint, and Lua 5.5 syntax for hand-written Hyprland Lua: the
  # harness itself now, and config/hypr as soon as the port adds it.
  luaSourcesCheck =
    pkgs.runCommand "hyprland-lua-static" {
      nativeBuildInputs = with pkgs; [
        stylua
        luaPackages.luacheck
        lua55
      ];
      checkDir = hyprlandCheckDir;
      configDir = productionConfigDir;
      luacheckrc = hyprlandCheckDir + "/.luacheckrc";
      HOME = "$TMPDIR";
    } ''
      set -euo pipefail
      stylua --check "$checkDir"
      luacheck --config "$luacheckrc" --no-cache "$checkDir" --exclude-files "$checkDir/lib/json.lua"

      if [ -d "$configDir" ]; then
        stylua --check "$configDir"
        luacheck --config "$luacheckrc" --no-cache "$configDir" --exclude-files "$configDir/lib/json.lua"
        find "$configDir" -name '*.lua' -print0 | while IFS= read -r -d "" f; do
          ${lua55}/bin/luac -p "$f"
        done
        echo "config/hypr present and clean"
      else
        echo "config/hypr not present yet; checked the harness only"
      fi

      find "$checkDir" -name '*.lua' -print0 | while IFS= read -r -d "" f; do
        ${lua55}/bin/luac -p "$f"
      done
      touch "$out"
    '';

  # The real parser gate on the verified fixture shapes. --verify-config never
  # starts the compositor loop, so it runs in a plain sandbox with only
  # XDG_RUNTIME_DIR set. The invalid fixtures must fail; a parser gate that
  # only accepts is not a gate.
  parserFixtureCheck =
    pkgs.runCommand "hyprland-parser-fixture" {
      nativeBuildInputs = [hyprland];
      fixtureDir = hyprlandCheckDir + "/verify-config";
      XDG_RUNTIME_DIR = "$TMPDIR/runtime";
    } ''
      set -euo pipefail
      mkdir -p "$XDG_RUNTIME_DIR"

      cat > "$TMPDIR/invalid-syntax.lua" <<'BROKEN'
      hl.bind("SUPER + W, hl.dsp.window.close()
      BROKEN

      if [ "${hyprland.version}" != "0.55.4" ]; then
        echo "hyprland parser gate must run on the pinned 0.55.4, got ${hyprland.version}" >&2
        exit 1
      fi

      HYPR="${hyprland}/bin/Hyprland"
      "$HYPR" --verify-config -c "$fixtureDir/valid.lua"
      echo "valid fixture: config ok"

      if "$HYPR" --verify-config -c "$fixtureDir/invalid-dispatcher.lua"; then
        echo "invalid-dispatcher fixture unexpectedly parsed" >&2
        exit 1
      fi
      echo "invalid-dispatcher fixture: rejected"

      if "$HYPR" --verify-config -c "$TMPDIR/invalid-syntax.lua"; then
        echo "invalid-syntax fixture unexpectedly parsed" >&2
        exit 1
      fi
      echo "invalid-syntax fixture: rejected"

      touch "$out"
    '';

  # Bridge contract tests under Lua 5.5, including the vendored decoder.
  bridgeCheck = luaTest "hyprland-bridge-tests" "bridge-test.lua" {};

  # Semantic parity harness tests in fixture mode.
  semanticCheck = luaTest "hyprland-semantic-fixture" "semantic-test.lua" {};

  # Production parity: red until the port ticket adds config/hypr. The gate
  # must stay in `checks` so `nix flake check` cannot pass while the hyprlang
  # configuration still owns the compositor.
  parityCheck = luaTest "hyprland-production-parity" "parity-test.lua" {};

  # The seam contract from the module-and-seam decision: configType = "lua"
  # generates hypr/hyprland.lua and must never coexist with hyprland.conf.
  # Proven by test against the Home Manager module at the flake's pinned rev;
  # the port ticket extends this fixture with the extraLuaFiles entries.
  ownershipCheck = let
    home = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        {
          home.username = "hyprland-test";
          home.homeDirectory = "/tmp/hyprland-test";
          home.stateVersion = "25.05";
          wayland.windowManager.hyprland = {
            enable = true;
            configType = "lua";
            package = null;
            portalPackage = null;
          };
        }
      ];
    };
    fileNames = builtins.attrNames home.config.xdg.configFile;
  in
    pkgs.runCommand "hyprland-ownership-fixture" {
      fileList = lib.concatStringsSep "\n" fileNames;
    } ''
      set -euo pipefail
      printf '%s\n' "$fileList" > files.txt
      grep -Fxq "hypr/hyprland.lua" files.txt \
        || { echo "FAIL: configType=lua did not generate hypr/hyprland.lua" >&2; exit 1; }
      if grep -Fxq "hypr/hyprland.conf" files.txt; then
        echo "FAIL: configType=lua generated hypr/hyprland.conf" >&2
        exit 1
      fi
      touch "$out"
    '';
in {
  hyprland-lua-static = luaSourcesCheck;
  hyprland-bridge-tests = bridgeCheck;
  hyprland-semantic-fixture = semanticCheck;
  hyprland-parser-fixture = parserFixtureCheck;
  hyprland-ownership-fixture = ownershipCheck;
  hyprland-production-parity = parityCheck;
}
