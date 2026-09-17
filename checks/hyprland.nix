{
  lib,
  pkgs,
  pkgs-stable,
  pkgs-darwin,
  pkgs-stable-darwin,
  dotfilesPkgs,
  dotfilesPkgs-darwin,
  inputs,
}: let
  root = inputs.self.outPath;
  checkDir = root + "/checks/hyprland";
  configDir = root + "/config/hypr";
  sourceReady = builtins.pathExists (configDir + "/entry.lua");
  lua = pkgs.lua5_5;
  hyprland = pkgs-stable.hyprland;
  baselineConf = builtins.readFile (root + "/docs/research/hyprland-live-baseline/generated/hyprland.conf");
  baselineMonitors = lib.filter (x: x != null) (map (line: let
    match = builtins.match "monitor[[:space:]]*=[[:space:]]*(.*)" line;
  in
    if match == null
    then null
    else builtins.head match) (lib.splitString "\n" baselineConf));

  repoHome = {
    homePkgs ? pkgs,
    releasePkgs ? pkgs-stable,
    packages ? dotfilesPkgs,
    enable ? true,
    homeDirectory ? "/home/fveracoechea",
    monitors ? baselineMonitors,
  }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = homePkgs;
      extraSpecialArgs = {
        pkgs-stable = releasePkgs;
        dotfilesPkgs = packages;
      };
      modules = [
        (root + "/modules/core/palette.nix")
        (root + "/modules/home-manager/hyprland")
        {
          home = {
            username = "hyprland-fixture";
            inherit homeDirectory;
            stateVersion = "25.05";
          };
          dotfiles.hyprland = {inherit enable monitors;};
        }
      ];
    };
  production = repoHome {};
  syntheticMonitor = "DP-9, preferred, auto, 1.25";
  synthetic = repoHome {
    homeDirectory = "/tmp/hyprland-fixture";
    monitors = [syntheticMonitor];
  };
  monitorUpdates = repoHome {
    monitors = [syntheticMonitor "DP-9, transform, 1" "DP-9, addreserved, 10, 20, 30, 40"];
  };
  emptyMonitors = repoHome {monitors = [];};
  darwin = repoHome {
    homePkgs = pkgs-darwin;
    releasePkgs = pkgs-stable-darwin;
    packages = dotfilesPkgs-darwin;
    enable = false;
  };

  # Stage Home Manager's sources, including directory sources and generated JSON.
  # No config or bridge data is supplied by this check.
  stage = home:
    pkgs.linkFarm "hyprland-config" (lib.mapAttrsToList (_: file: {
      name = lib.removePrefix "${lib.removePrefix "${home.config.home.homeDirectory}/" home.config.xdg.configHome}/" file.target;
      path = file.source;
    }) (lib.filterAttrs (_: file: file.enable) home.config.xdg.configFile));
  productionStage = assert production.config.wayland.windowManager.hyprland.extraConfig == ''require("lifecycle")'';
  assert nativeOwnership production; stage production;
  syntheticStage = stage synthetic;

  nativeOwnership = home: let
    cfg = home.config.wayland.windowManager.hyprland;
    files = home.config.xdg.configFile;
  in
    cfg.configType
    == "lua"
    && cfg.settings == {}
    && (
      cfg.extraConfig
      == ""
      || (cfg.extraConfig == ''require("lifecycle")'' && cfg.extraLuaFiles ? lifecycle && !cfg.extraLuaFiles.lifecycle.autoLoad)
    )
    && files ? "hypr/hyprland.lua"
    && !(files ? "hypr/hyprland.conf")
    && builtins.attrNames (lib.filterAttrs (_: file: file.autoLoad) cfg.extraLuaFiles) == ["entry"];

  # Upstream shape check only. This is not the repo's production Home.
  upstream = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      {
        home = {
          username = "upstream-fixture";
          homeDirectory = "/tmp/upstream-fixture";
          stateVersion = "25.05";
        };
        wayland.windowManager.hyprland = {
          enable = true;
          package = null;
          portalPackage = null;
          configType = "lua";
          settings = {};
          extraLuaFiles.entry = {
            content = ./hyprland/verify-config/valid.lua;
            autoLoad = true;
          };
        };
      }
    ];
  };
  upstreamStage = assert nativeOwnership upstream; stage upstream;

  systemConfig =
    (inputs.nixpkgs-stable.lib.nixosSystem {
      specialArgs = {inherit dotfilesPkgs;};
      modules = [
        (root + "/modules/nixos/hyprland.nix")
        {
          nixpkgs.pkgs = pkgs-stable;
          dotfiles.hyprland.enable = true;
          system.stateVersion = "25.05";
        }
      ];
    }).config;
  homeConfig = synthetic.config;
  homePackages = map (p: p.drvPath) homeConfig.home.packages;
  ownership =
    homeConfig.wayland.windowManager.hyprland.package
    == null
    && homeConfig.wayland.windowManager.hyprland.portalPackage == null
    && homeConfig.services.hypridle.package.drvPath == pkgs-stable.hypridle.drvPath
    && homeConfig.programs.hyprlock.package.drvPath == pkgs-stable.hyprlock.drvPath
    && homeConfig.services.hyprpaper.package.drvPath == pkgs-stable.hyprpaper.drvPath
    && lib.all (p: builtins.elem p.drvPath homePackages) [
      dotfilesPkgs.ultrashell
      pkgs-stable.quickshell
      pkgs-stable.hyprpaper
      pkgs-stable.hyprshot
      pkgs-stable.hyprpicker
      pkgs-stable.hyprcursor
    ]
    && systemConfig.programs.hyprland.package.drvPath == hyprland.drvPath
    && systemConfig.programs.hyprland.portalPackage.drvPath == pkgs-stable.xdg-desktop-portal-hyprland.drvPath
    && systemConfig.programs.hyprland.withUWSM
    && systemConfig.programs.hyprland.xwayland.enable;

  luaTest = name: script:
    pkgs.runCommand name {nativeBuildInputs = [lua];} ''
      export HOME="$TMPDIR"
      lua ${checkDir}/${script} ${root}
      touch "$out"
    '';
  missingSource = name:
    pkgs.runCommand name {} ''
      echo "${name}: config/hypr/entry.lua does not exist yet; issue 37 must add the native source." >&2
      exit 1
    '';
  parserSetup = ''
    export XDG_RUNTIME_DIR="$TMPDIR/runtime"
    mkdir -p "$XDG_RUNTIME_DIR"
    test '${hyprland.version}' = '0.55.4'
  '';
in {
  hyprland-lua-static =
    pkgs.runCommand "hyprland-lua-static" {
      nativeBuildInputs = [pkgs.stylua pkgs.luaPackages.luacheck lua];
    } ''
      set -euo pipefail
      export HOME="$TMPDIR"
      for directory in ${checkDir} ${configDir}; do
        [ -d "$directory" ] || continue
        stylua --check "$directory"
        luacheck --config ${checkDir}/.luacheckrc --no-cache "$directory" --exclude-files "$directory/lib/json.lua"
        find "$directory" -name '*.lua' -print0 | while IFS= read -r -d "" file; do
          ${lua}/bin/luac -p "$file"
        done
      done
      touch "$out"
    '';
  hyprland-bridge-tests = luaTest "hyprland-bridge-tests" "bridge-test.lua";
  hyprland-semantic-fixture = luaTest "hyprland-semantic-fixture" "semantic-test.lua";

  hyprland-parser-fixture = pkgs.runCommand "hyprland-parser-fixture" {} ''
    ${parserSetup}
    ${hyprland}/bin/Hyprland --verify-config -c ${checkDir}/verify-config/valid.lua
    printf '%s\n' 'hl.bind("SUPER + W, hl.dsp.window.close()' > "$TMPDIR/invalid-syntax.lua"
    for file in ${checkDir}/verify-config/invalid-dispatcher.lua "$TMPDIR/invalid-syntax.lua"; do
      if ${hyprland}/bin/Hyprland --verify-config -c "$file"; then
        echo "Invalid fixture unexpectedly parsed: $file" >&2
        exit 1
      fi
    done
    export XDG_CONFIG_HOME=${upstreamStage}
    export HOME=/tmp/upstream-fixture
    cmp ${upstreamStage}/hypr/entry.lua ${checkDir}/verify-config/valid.lua
    ${hyprland}/bin/Hyprland --verify-config -c ${upstreamStage}/hypr/hyprland.lua
    touch "$out"
  '';

  hyprland-repo-ownership = assert ownership;
  assert lib.all (name: builtins.hasAttr "hypr/${name}.conf" homeConfig.xdg.configFile) ["hypridle" "hyprlock" "hyprpaper"];
  assert !darwin.config.wayland.windowManager.hyprland.enable;
  assert lib.all (name: !(lib.hasPrefix "hypr/" name) && name != "dotfiles/hyprland.json") (builtins.attrNames darwin.config.xdg.configFile);
  assert if sourceReady
  then nativeOwnership synthetic
  else
    homeConfig.wayland.windowManager.hyprland.configType
    == "hyprlang"
    && !(homeConfig.xdg.configFile ? "hypr/hyprland.lua");
    pkgs.runCommand "hyprland-repo-ownership" {
      nativeBuildInputs = [pkgs.jq lua];
      XDG_CONFIG_HOME = syntheticStage;
      HOME = "/tmp/hyprland-fixture";
    } (
      if sourceReady
      then ''
        jq -e --arg monitor '${syntheticMonitor}' \
          --argjson theme '${builtins.toJSON {inherit (homeConfig.dotfiles.palette) blue flamingo surface2;}}' '
          .monitors == [$monitor] and .theme == $theme and
          .paths.fuzzelCache == "/tmp/hyprland-fixture/.config/fuzzel/cache"' \
          "$XDG_CONFIG_HOME/dotfiles/hyprland.json"
        lua - ${checkDir} "$XDG_CONFIG_HOME/hypr" <<'LUA'
        package.path = arg[1] .. "/?.lua;" .. package.path
        local directory = arg[2]
        local file = assert(io.open(directory .. "/hyprland.lua"))
        local state = require("capture").run(file:read("*a"), directory)
        file:close()
        local records = require("records")
        assert(#records.diff_monitors(state.monitors, {"${syntheticMonitor}"}) == 0,
          "synthetic monitor did not reach the native config")
        local found = false
        for _, bind in ipairs(state.binds) do
          local dispatcher = assert(records.legacy_dispatcher(bind.dispatcher))
          if dispatcher.dispatcher == "exec" and dispatcher.arg == "fuzzel --cache /tmp/hyprland-fixture/.config/fuzzel/cache" then
            found = true
          end
        end
        assert(found, "synthetic Home cache path did not reach the native config")
        LUA
        touch "$out"
      ''
      else ''
        grep -Fq 'monitor=${syntheticMonitor}' "$XDG_CONFIG_HOME/hypr/hyprland.conf"
        grep -Fq 'fuzzel --cache /tmp/hyprland-fixture/.config/fuzzel/cache' "$XDG_CONFIG_HOME/hypr/hyprland.conf"
        touch "$out"
      ''
    );

  hyprland-production-parity =
    if !sourceReady
    then missingSource "hyprland-production-parity"
    else
      pkgs.runCommand "hyprland-production-parity" {
        nativeBuildInputs = [lua];
        XDG_CONFIG_HOME = productionStage;
        HOME = production.config.home.homeDirectory;
      } ''
        lua ${checkDir}/parity-test.lua ${root} \
          "$XDG_CONFIG_HOME/hypr/hyprland.lua" \
          ${pkgs.dbus}/bin/dbus-update-activation-environment
        mkdir -p "$TMPDIR/bridge/dotfiles"
        for fixture in missing malformed missing-theme-color null-monitors; do
          if [ "$fixture" != missing ]; then
            cp --remove-destination ${checkDir}/fixtures/bridge/"$fixture.json" "$TMPDIR/bridge/dotfiles/hyprland.json"
          fi
          XDG_CONFIG_HOME="$TMPDIR/bridge" lua ${checkDir}/startup-validation-test.lua \
            ${root} ${productionStage}/hypr/hyprland.lua invalid
        done
        cp --remove-destination ${checkDir}/fixtures/bridge/empty-monitors.json "$TMPDIR/bridge/dotfiles/hyprland.json"
        XDG_CONFIG_HOME="$TMPDIR/bridge" lua ${checkDir}/startup-validation-test.lua \
          ${root} ${productionStage}/hypr/hyprland.lua empty
        touch "$out"
      '';
  hyprland-production-parser =
    if !sourceReady
    then missingSource "hyprland-production-parser"
    else
      pkgs.runCommand "hyprland-production-parser" {
        XDG_CONFIG_HOME = productionStage;
        HOME = production.config.home.homeDirectory;
      } ''
        ${parserSetup}
        for configHome in ${productionStage} ${stage monitorUpdates} ${stage emptyMonitors}; do
          export XDG_CONFIG_HOME="$configHome"
          ${hyprland}/bin/Hyprland --verify-config -c "$XDG_CONFIG_HOME/hypr/hyprland.lua"
        done
        touch "$out"
      '';
}
