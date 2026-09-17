# Hyprland Lua quality-gate evidence

Date: 2026-09-17.
Task: [Run the automated Hyprland Lua quality gates](https://github.com/fveracoechea/dotfiles/issues/39).
Base: `23cd088`, the integrated production port.
Platform: `x86_64-linux`.

## Result

All nine declared Linux flake checks pass.
Both declared Darwin checks evaluate, but were not built on this Linux host.
The desktop and MacBook configuration derivations evaluate without a System build.
The seven Hyprland checks also passed a forced rebuild before the format and lint fixes.

- Semantic and lifecycle fixtures: 193 checks pass.
- JSON bridge: 88 checks pass.
- Production parity: 8 checks pass, including all 46 ordered binding records.
- Startup validation: five invalid bridges fail before side effects, and an empty monitor array succeeds.
- Hyprland 0.55.4 parser: valid fixture and upstream Home Manager entry pass; invalid dispatcher and syntax fixtures fail as expected.
- Production parser: baseline monitors, ordered monitor updates, and empty monitors pass.
- Ownership fixture: Linux package ownership and Darwin exclusion assertions pass.
- Lua formatting and lint: zero warnings or errors across 15 harness files, 8 production files, and 31 Neovim files.
- Lua 5.5 syntax: all harness and production Lua files pass, including the vendored decoder.
- Baseline validator: all 12 self-test cases and the committed baseline pass.
- Nix formatting: all 66 files pass Alejandra 4.0.0.
- ShellCheck 0.11.0 and Bash syntax: all three repository shell scripts pass.

The parity checks retain only the [approved shutdown exception](https://github.com/fveracoechea/dotfiles/issues/34#issuecomment-5713303720).
Changed commands, changed order, duplicate shutdown work, and other wait durations remain rejected.

## Failures and fixes

`alejandra --check .` initially exited 2 and named six files.
Only their function argument layout changed:

- `modules/home-manager/bat.nix`
- `modules/home-manager/btop.nix`
- `modules/home-manager/desktop-entries/default.nix`
- `modules/home-manager/fonts.nix`
- `modules/home-manager/pro-audio.nix`
- `packages/stylelint-language-server.nix`

ShellCheck initially exited 1 with SC2086 in `scripts/capture-hyprland-baseline.sh`.
The validator used unquoted expansion of a space-separated list of bind fields.
It now uses a Bash array and quoted expansion.
The existing tests still reject records without `locked` or `description`.
No baseline data or compositor behavior changed.

## Yazi reproduction attempts

The reported invalid `v6pp2bjbrxi80x7kr9c9x8pwap19xzjq-source.drv` failure did not reproduce in this worktree.
All four commands below exited 0 before any edits:

```sh
nix flake check --no-build --show-trace
nix flake check --no-build --option eval-cache false --show-trace
nix eval --option eval-cache false --json .#nixosConfigurations.nixos-desktop.config.home-manager.users.fveracoechea.programs.yazi.theme --apply builtins.attrNames
nix eval --option eval-cache false --json .#darwinConfigurations.macbook-pro.config.home-manager.users.fveracoechea.programs.yazi.theme --apply builtins.attrNames
```

Both theme evaluations returned the same 18 top-level theme keys.
No root cause is claimed for a failure that could not be reproduced here.
There was no Yazi edit, store repair, lock update, channel update, or System change.

## Gate commands

Run each command from the repository root.
Each final command exited 0.

```sh
alejandra --check .
git diff --check
nix flake check --print-build-logs
nix flake check --all-systems --no-build --option eval-cache false --show-trace
nix shell --impure --expr '(builtins.getFlake (toString ./.)).inputs.nixpkgs-latest.legacyPackages.x86_64-linux.shellcheck' --command shellcheck scripts/capture-hyprland-baseline.sh scripts/check-lua.sh modules/home-manager/coding-agents/claude-statusline.sh
bash -n scripts/capture-hyprland-baseline.sh scripts/check-lua.sh modules/home-manager/coding-agents/claude-statusline.sh
bash scripts/capture-hyprland-baseline.sh test
bash scripts/capture-hyprland-baseline.sh validate docs/research/hyprland-live-baseline
```

The full Linux check printed `all checks passed!`.
It includes both Neovim checks, not only the Hyprland checks.
The all-systems command evaluates both Darwin checks without requesting a Darwin build.
The ShellCheck command uses the existing locked Latest Channel input.

Forced Hyprland rebuild, exit 0:

```sh
nix build --no-link --rebuild --print-build-logs .#checks.x86_64-linux.hyprland-lua-static .#checks.x86_64-linux.hyprland-bridge-tests .#checks.x86_64-linux.hyprland-semantic-fixture .#checks.x86_64-linux.hyprland-parser-fixture .#checks.x86_64-linux.hyprland-repo-ownership .#checks.x86_64-linux.hyprland-production-parity .#checks.x86_64-linux.hyprland-production-parser
```

## Host evaluations

The fixture ownership check evaluates an enabled Linux Home, a disabled Darwin Home, and the Linux System module.
The following extra commands force evaluation of both complete host derivations without building them.
Both exited 0:

```sh
nix eval --option eval-cache false --raw .#nixosConfigurations.nixos-desktop.config.system.build.toplevel.drvPath
nix eval --option eval-cache false --raw .#darwinConfigurations.macbook-pro.system.drvPath
```

Actual desktop Home assertions, exit 0:

```sh
nix eval --option eval-cache false --json .#nixosConfigurations.nixos-desktop.config --apply 'c: let h = c.home-manager.users.fveracoechea; hypr = h.wayland.windowManager.hyprland; files = h.xdg.configFile; in assert c.programs.hyprland.enable; assert c.programs.hyprland.package.version == "0.55.4"; assert hypr.enable && hypr.configType == "lua"; assert hypr.settings == {}; assert hypr.package == null && hypr.portalPackage == null; assert hypr.extraConfig == "require(\"lifecycle\")"; assert files ? "hypr/hyprland.lua" && !(files ? "hypr/hyprland.conf"); assert builtins.all (n: builtins.hasAttr "hypr/${n}.conf" files) ["hypridle" "hyprlock" "hyprpaper"]; { host = "nixos-desktop"; version = c.programs.hyprland.package.version; configType = hypr.configType; monitors = h.dotfiles.hyprland.monitors; bridge = builtins.fromJSON files."dotfiles/hyprland.json".text; }'
```

Output confirms `configType = "lua"`, Hyprland `0.55.4`, both host monitor strings, the three raw Theme colors, and `/home/fveracoechea/.config/fuzzel/cache`.

Actual MacBook Home assertions, exit 0:

```sh
nix eval --option eval-cache false --json .#darwinConfigurations.macbook-pro.config --apply 'c: let h = c.home-manager.users.fveracoechea; files = builtins.attrNames h.xdg.configFile; in assert !h.dotfiles.hyprland.enable; assert !h.wayland.windowManager.hyprland.enable; assert builtins.all (n: builtins.match "hypr/.*" n == null && n != "dotfiles/hyprland.json") files; { host = "macbook-pro"; hyprlandEnabled = h.wayland.windowManager.hyprland.enable; hyprlandFiles = builtins.filter (n: builtins.match "hypr/.*" n != null || n == "dotfiles/hyprland.json") files; }'
```

Output is `{"host":"macbook-pro","hyprlandEnabled":false,"hyprlandFiles":[]}`.

## Limits and final integration

- Native Darwin builds and runtime tests were not run on Linux.
- Nix warns about the custom `homeManagerModules` and `dotfilesPkgs` outputs.
- The Neovim smoke test passes but reports `gitsigns: git not in path. Aborting setup` in its isolated environment; it does not prove Gitsigns runtime behavior.
- No System build, activation, rebuild command, live reload, or dispatch was run.
- The user-run desktop session gate remains required.
- The coordinator must rerun the gate commands after integrating these fixes and the documentation task.
- This work does not close the ticket, edit the map, push commits, or clean worktrees.
