# Verifying the Hyprland hyprlang to Lua migration

Research date: 2026-09-12. Researched against Home Manager at the repo's pinned rev
`2c0350c759688177331b8f5242311fae8877bdb3`, Hyprland `v0.55.4` (the version nixos-26.05
ships and this repo runs), and nixpkgs `nixpkgs-unstable` at
`42f17a57f4f6e33b3de3dca0a2a5ea5233169d02`. Every empirical claim in sections 3, 4, and 6
was tested on this machine (`nixos-desktop`, live Hyprland 0.55.4 session) or inside a Nix
sandbox on 2026-09-12.

## TL;DR verdict

The migration can be gated end to end without ever building or activating system config:

1. Home Manager's hyprland module renders the existing `settings` attrset to
   `hl.<name>(...)` Lua calls, so the migration is a Nix-side change, not a config rewrite.
2. `Hyprland --verify-config` is a real headless parser check: it exits 0 on a valid config,
   1 on any parse or type error, works for both Lua and hyprlang, and runs inside a plain
   Nix sandbox with only `XDG_RUNTIME_DIR` set. I confirmed this empirically.
3. `nix flake check` can therefore run stylua, luacheck, a Lua syntax check, the real
   Hyprland parser, and a stub-exec call-log diff on the generated `hyprland.lua`, following
   the existing `checks/neovim.nix` pattern.
4. The end-user live gate is `nixos-rebuild test --flake .#nixos-desktop`, then
   `hyprctl reload config-only`, `hyprctl configerrors` (expect empty), and a
   `hyprctl binds -j` count plus `hyprctl getoption` spot checks against a before-snapshot.
   Rollback is `nixos-rebuild test --rollback` (no `--flake`).

The one thing automation cannot fully do is prove old hyprlang binds and new `hl.bind` calls
are equivalent, because they are not mechanically equivalent: the Lua API restructures binds
from one comma string into positional arguments plus dispatcher objects. A recorded
before-snapshot from the live session closes that gap.

## 1. Background: what changed in Hyprland 0.55

- Hyprland 0.55 (released 2026-05-09) made Lua the configuration language. The config file
  is `hyprland.lua`; wiki: https://hypr.land/news/update55/ and
  https://wiki.hypr.land/Configuring/Start/
- hyprlang is deprecated. The 2026-04-26 announcement says: "The old hyprlang syntax will
  continue to be supported for 1 - 2 releases starting from 0.55. After that, hyprlang will
  be dropped. New config features will also not be added to hyprlang anymore."
  https://hypr.land/news/26_lua/
- At startup Hyprland checks once for `hyprland.lua`; if present it wins over
  `hyprland.conf`. Same check in reverse. https://hypr.land/news/26_lua/
- Hyprland 0.56 shipped 2026-07-20 (news list on hypr.land). So the "1 - 2 releases"
  hyprlang window is already half used. nixos-26.05 still ships hyprland 0.55.4, which this
  repo holds on purpose (see `modules/home-manager/hyprland/settings.nix:16`).
- Hyprland embeds Lua 5.5: `CMakeLists.txt` at `v0.55.4` line 277 asks pkg-config for
  `lua55 lua5.5 lua-55 lua-5.5 lua>=5.5 lua<5.6`.

Error behavior (wiki, Configuring/Start):

- Fundamental Lua syntax errors make Hyprland refuse to reload the config and pop an error.
- Runtime Lua errors (calling nil) abort the current file and pop an error.
- Runtime Hyprland type errors (wrong argument type) continue execution and pop an error.
- Errors in one `require`d file do not stop other files; each `require` is its own scope.

This error taxonomy matters for the gate: a lint pass plus the real parser covers the first
two classes; the third class only shows up in `hyprctl configerrors` on a live session or in
a stub-exec harness that checks argument shapes.

## 2. Home Manager Lua support (`wayland.windowManager.hyprland`)

Source: `modules/services/window-managers/hyprland/{default,lib}.nix` at home-manager rev
`2c0350c` (the repo's pin). The module was split out of the single `hyprland.nix` file; the
old path is a shim (PR 7304).

### configType

- `wayland.windowManager.hyprland.configType` is an enum `"hyprlang" | "lua"`
  (`default.nix:226`).
- Default comes from `lib.hm.deprecations.mkStateVersionOptionDefault`: `hyprlang` for
  `home.stateVersion < 26.05`, `lua` from 26.05 on. This repo's
  `home.stateVersion = "24.05"` (`hosts/nixos-desktop/home.nix:78`), so after the migration
  `configType = "lua"` must be set explicitly, the same way `configType = "hyprlang"` is set
  today (`modules/home-manager/hyprland/settings.nix:20`).
- `"hyprlang"` writes `$XDG_CONFIG_HOME/hypr/hyprland.conf`; `"lua"` writes
  `.../hypr/hyprland.lua`.

### How `settings` renders to Lua (`lib.nix`, `luaConfig`)

- Every attribute becomes `hl.<name>(<value>)`; list values emit one call per element.
- An attrset value with an `_args` list renders as a multi-argument call:
  `bind = { _args = [ "SUPER" "Q" (mkLuaInline "hl.dsp.window.close()") ]; }` renders as
  `hl.bind("SUPER", "Q", hl.dsp.window.close())`.
- An attrset with `_var` renders a `local <name> = ...` instead of a call.
- `lib.generators.mkLuaInline` renders raw Lua expressions (used for dispatchers and
  functions inside binds).
- `systemd.enable` renders as `hl.on("hyprland.start", ...)` plus a shutdown hook; plugins
  render as `hl.plugin.load(...)`; `submaps` render as `hl.define_submap(...)`.
- `extraLuaFiles` writes sibling modules under `$XDG_CONFIG_HOME/hypr/` and prepends
  `package.path` plus `require()` lines into `hyprland.lua`. This is how the config could be
  split into `bindings.lua`, `theme.lua`, and so on later.
- Assertions forbid `extraLuaFiles` defining `hyprland.lua` and duplicate targets.

### Two gaps that affect this repo

1. `onChange` reload is skipped when `package = null`. The generated file gets
   `onChange = reloadConfig`, and `reloadConfig` calls `cfg.finalPackage`'s hyprctl across
   all instances. This repo sets `package = null` (the NixOS module owns Hyprland), so
   `finalPackage` is null and no auto reload happens on activation. After
   `nixos-rebuild test`, the user must run `hyprctl reload config-only` manually. Hyprland
   also watches the config file and reloads on change, but manual reload is the reliable
   path and also drains `configerrors`.
2. The generated `.luarc.json` (pointing LuaLS at `${finalPackage}/share/hypr/stubs` with
   `diagnostics.globals = [ "hl" ]`) is also gated on `finalPackage != null`, so this repo
   will not get one. The repo should add its own `.luarc.json` entry (the repo already has
   one at the root for nvim) that references the stubs path of whatever hyprland derivation
   is pinned, or checks can export it.

### What does not change

`hypridle.nix`, `hyprlock.nix`, `hyprpaper.nix`, and `hyprcursor.nix` are separate programs
and keep their own config formats. Only `settings`, `bindings`, `env`, `windowrules`, and
`theme` feed `wayland.windowManager.hyprland.settings`.

## 3. Hyprland validation and reload facilities (tested)

### `Hyprland --verify-config` (the key facility)

From `src/main.cpp` at `v0.55.4`: the flag sets `verifyConfig`, the compositor constructor
runs with it, and after `initServer` the process returns
`!Config::mgr()->configVerifPassed()` (`main.cpp:268`). Usage text:
`--verify-config - Do not run Hyprland, only print if the config has any errors`.
`--config FILE` / `-c FILE` selects the file.

Empirical results on this machine (Hyprland 0.55.4 from nixos-26.05):

| Input | Result |
|---|---|
| Valid `hl.config({...})` file | exit 0, prints `config ok` |
| File with an unfinished string | exit 1, prints the exact file:line error |
| Legacy `hyprland.conf` (`general { ... }`, `bind = SUPER, Q, exec, ghostty`) | exit 0, `config ok` |
| `hl.bind("SUPER", "Q", hl.dsp.exec_cmd("ghostty"))` | exit 1, `hl.bind: dispatcher must be a dispatcher (e.g. hl.dsp.window.close()) or a lua function` |

The last row is significant: the parser catches API-shape errors, not just syntax, and it
flags a realistic migration mistake.

### Sandbox feasibility (tested)

I ran `Hyprland --verify-config -c <valid.lua>` inside a `stdenv.mkDerivation` build
sandbox:

```
export XDG_RUNTIME_DIR=$TMPDIR/runtime
mkdir -p $XDG_RUNTIME_DIR
$hypr/bin/Hyprland --verify-config -c $TMPDIR/test.lua
```

with `hypr = pkgs.hyprland` (nixos-26.05, 0.55.4) as a derivation input. Result: `config ok`,
exit 0 for the valid file, exit 1 for the broken one. No GPU, no seat, no display server
needed, because `--verify-config` never starts the compositor loop. This means a flake check
derivation can run the real parser on generated config. The one requirement is that the
hyprland package appears as a derivation input so the sandbox can see it.

### hyprctl (live session, tested)

- `hyprctl reload [config-only]` reloads the config.
- `hyprctl configerrors` lists all current config parsing errors; empty output means clean.
  Tested on the live session: empty while the current hyprlang config parses clean.
- `hyprctl getoption <option>` shows the value and `set: true|false` per option (tested
  `general:gaps_in`, `general:layout`).
- `hyprctl binds -j` lists registered binds; tested: 46 binds in the current session.
- `hyprctl rollinglog` tails the log.
- A Lua REPL is built into hyprctl (wiki, Configuring/Start) for exploring `hl` state.

### LuaLS stubs

- The build generates stubs with `meta/generateLuaStubs.py` (CMake target
  `generate-lua-stubs`).
- The installed nixpkgs package ships them at `share/hypr/stubs/` (confirmed:
  `/run/current-system/sw/share/hypr/stubs/hl.meta.lua` from hyprland 0.55.4, and the same
  path in the 0.56.0 store path). The wiki documents wiring them into a `.luarc.json`.

## 4. Lua tooling in current nixpkgs

All attributes verified via search.nixos.org against `nixpkgs-unstable`
(`42f17a57`):

| Tool | Attribute | Version | Role in the gate |
|---|---|---|---|
| stylua | `stylua` | 2.5.2 | format check (`stylua --check`), already used by `checks/neovim.nix` |
| luacheck | `lua54Packages.luacheck` (also lua53/luajit variants) | 1.2.0-1 | lint, already used with the root `.luacheckrc` |
| selene | `selene` | 0.31.0 | alternative/additional linter, needs a `selene.toml` schema |
| lua-language-server | `lua-language-server` | 3.19.1 | type check of generated config against Hyprland's stubs (`lua-language-server --check`) |
| lua | `lua5_5` | 5.5.0 | syntax check (`luac -p`) matching the interpreter Hyprland embeds |

The repo already formats and lints its nvim Lua with stylua + luacheck
(`.stylua.toml`, `.luacheckrc`, `checks/neovim.nix:95`), so the tooling and conventions
exist. A second `.luacheckrc` (or a per-directory override) is needed for generated Hyprland
config because `hl` is a new global and the std differs from nvim's lua54 world. Hyprland
embeds Lua 5.5, so syntax checking with `lua5_5`'s `luac -p` is the closest match; luacheck
has no 5.5 mode and `lua54` is the closest lint target.

## 5. Automated tests without building system config

The repo already has the pattern: `checks/neovim.nix` evaluates a
`homeManagerConfiguration` with the real module tree and a fixture user, then runs
`runCommand` smoke and lint checks. Flake checks are evaluated and built by
`nix flake check` and never touch the system profile. A `checks/hyprland.nix` would:

1. Evaluate a `homeManagerConfiguration` importing
   `modules/home-manager/hyprland/` with `dotfiles.hyprland.enable = true` and a fixture
   `dotfiles.hyprland.monitors`, with `configType = "lua"`.
2. Read the generated file. The module lands `hyprland.lua` via the `xdg.configFile` file
   tree, so the text is available at eval time through
   `config.xdg.configFile."hypr/hyprland.lua".source` (a store path readable with
   `builtins.readFile`) or by building the config's `home-files` output inside the check.
3. Run gates in `runCommand` derivations:
   - `stylua --check` on the generated directory (stabilize the generated file's formatting
     expectation first; generated output is machine formatted, so if stylua disagrees with
     the renderer, format the rendered text with stylua first and check the result, or drop
     this gate for generated files and keep it for hand-written `extraLuaFiles`).
   - `luacheck` with a Hyprland-specific config (`globals = hl`, `std = max`).
   - `lua5_5` syntax check (`luac -p` or `assert(load(text))`).
   - `Hyprland --verify-config -c` on the generated file (see section 3 for the proven
     sandbox recipe).
   - A stub-exec harness: run the generated file under `lua5_5` with a stub `hl` global that
     records every call into a normalized log (dispatchers recorded as
     `dsp.<path>(<args>)`). This catches nil-indexing and argument-shape errors the parser
     only reports at runtime type-check time, and it produces a machine-readable summary of
     what the config will do (option calls, bind count, windowrule count) that can be
     diffed against a golden file or against expectations derived from `settings`.
4. Register in `flake.nix` `checks` next to `neovimChecks` and wire into
   `nix flake check`.

### Semantic parity between hyprland.conf and hyprland.lua

Both render from the same `settings` attrset, but not mechanically equivalently:

- Options like `general.gaps_in`, `decoration.*`, `monitor` render to the same values in
  both languages. For these, a dual-render diff works: evaluate the module twice
  (`configType = "hyprlang"` and `"lua"`), parse the hyprlang text into
  `section.path = value` pairs, run the Lua through the stub harness to get the same pairs
  from `hl.config(...)` calls, and diff. Both parsers are small and the option surface this
  repo uses is modest.
- Binds do not map mechanically. hyprlang `bindd = "SUPER, T, Toggle floating, togglefloating"`
  becomes `hl.bind("SUPER", "T", <description?>, hl.dsp.togglefloating())` with the
  description as a positional argument and the dispatcher as an object created by calling
  `hl.dsp.<name>(args)`. My sandbox test showed `hl.bind` rejects a dispatcher built the
  wrong way. So parity for binds is best captured as: hyprlang bind string count and
  dispatcher name extracted from the strings must equal the stub-exec call-log count and
  dispatcher names. That is a strong check: it proves no bind was dropped or renamed, even
  though it cannot prove flag-for-flag identity inside each bind.
- Monitor and workspace rule strings pass through as data in both languages and diff
  cleanly.

A before-snapshot from the live session (`hyprctl getoption` dump of the options the repo
sets, `hyprctl binds -j`, `hyprctl workspacerules -j`) recorded on the current hyprlang
config gives the reference the after-snapshot must match. This is the strongest available
parity evidence because the compositor itself is the oracle.

## 6. Proposed quality gate

Ordered from cheapest to most human:

Gate A: static, in `nix flake check`, no Hyprland build.

- stylua/luacheck on generated and hand-written Lua.
- Lua 5.5 syntax check on every generated `.lua` file.

Gate B: real parser, in `nix flake check`.

- `Hyprland --verify-config` on the generated `hyprland.lua` (sandbox recipe in section 3).
- Stub-exec call log: no nil-index errors, and counts match expectations (bind count,
  windowrule count, exec-once count) computed from the `settings` attrset in Nix.

Gate C: dual-render parity, in `nix flake check`.

- Option values, monitor strings, and workspace rules extracted from hyprlang and Lua
  renders of the same `settings` must be equal.
- Bind dispatcher names and counts extracted both ways must be equal.

Gate D: end-user live gate (user runs this, see section 7).

- `hyprctl configerrors` empty, getoption spot checks and binds count equal to the recorded
  before-snapshot, visual smoke of the session.

The migration is done only when A through D pass and the hyprlang `configType` fallback is
removed (no `hyprland.conf` left on disk, so the lua-vs-conf startup check can never pick
the wrong file).

## 7. End-user test and rollback procedure (nixos-rebuild test)

Before migrating, record a snapshot from the live session:

```
hyprctl binds -j > /tmp/hypr-binds-before.json
hyprctl workspacerules -j > /tmp/hypr-wsrules-before.json
for o in general:gaps_in general:gaps_out general:border_size general:layout \
         decoration:rounding misc:vrr binds:drag_threshold binds:allow_workspace_cycles; do
  hyprctl -j getoption "$o"
done > /tmp/hypr-options-before.json
```

Test (applies user config to the running system without adding a boot entry):

```
nixos-rebuild test --flake .#nixos-desktop
```

Verify (the HM `onChange` reload is skipped because `package = null`, so reload by hand):

```
hyprctl reload config-only
hyprctl configerrors        # expect empty output
hyprctl binds -j | jq length  # compare with /tmp/hypr-binds-before.json count
hyprctl getoption general:gaps_in
ls -la ~/.config/hypr/       # hyprland.lua present, no hyprland.conf
```

Then use the session normally for a few minutes (bindings, launcher, workspaces). The
`nixos-rebuild test` action changes the system profile but not the bootloader default, so a
reboot returns to the last `switch`/`boot` configuration.

Rollback if the session misbehaves:

```
nixos-rebuild test --rollback    # no --flake; reactivates the previous system profile generation
hyprctl reload config-only       # or restart the compositor from the display manager
```

`--rollback` activates the generation before the current one of
`/nix/var/nix/profiles/system` (nixos-rebuild(8)), which restores the previous
`hyprland.lua`/`hyprland.conf` set, since the HM-generated files live inside that profile.
If only the compositor needs restarting, selecting the Hyprland session again from the
display manager (or `hyprctl dispatch exit`) relaunches with the on-disk config.

## 8. Uncertainties

- `--verify-config` was proven in a sandbox for a small config. A full generated config
  pulls in `require`d `extraLuaFiles` and `os.getenv("XDG_CONFIG_HOME")`; the harness must
  set `XDG_CONFIG_HOME` to a directory mirroring the generated layout. Expected to work,
  not yet exercised at full scale.
- The stub-exec harness needs a stub `hl` whose dispatcher constructors behave like the
  real ones (return opaque dispatcher objects). The stub surface is derivable from
  `share/hypr/stubs/hl.meta.lua`, but writing it is real work and its fidelity bounds what
  Gate B can catch.
- Whether Hyprland's file watcher auto-reloads when HM replaces the `hyprland.lua` symlink
  target during activation is untested; the manual `hyprctl reload config-only` step makes
  this moot.
- Bind parity (Gate C) proves counts and dispatcher names, not argument-for-argument
  equivalence (for example `fullscreenstate` flag orders inside a bind string). The
  before/after live snapshot narrows this but does not eliminate it.
- HM pinned at `2c0350c` is a fast-moving module (PR 7304 restructured it); the option
  surface documented here (`configType`, `_args`, `_var`, `extraLuaFiles`) should be
  re-checked after any flake update of home-manager.
- nixos-26.05 holds hyprland 0.55.4, but unstable is at 0.56.2. If the Release Channel
  bumps to 0.57 during the migration window, hyprlang support may already be gone; the
  migration should not wait for that.

## 9. Primary sources

- Hyprland 0.55 announcement: https://hypr.land/news/update55/
- Lua-ification announcement (deprecation timeline, lua-wins-over-conf check):
  https://hypr.land/news/26_lua/
- Hyprland wiki, Configuring/Start (config location, reload, require, error taxonomy,
  stubs, REPL): https://wiki.hypr.land/Configuring/Start/
- Hyprland `v0.55.4` source: `src/main.cpp` (`--verify-config`, exit
  `!configVerifPassed()`), `CMakeLists.txt` (Lua 5.5 dependency, `generate-lua-stubs`),
  `meta/generateLuaStubs.py`
  https://github.com/hyprwm/Hyprland/tree/v0.55.4-b
- Hyprland v0.55.0 changelog (config/lua items): https://github.com/hyprwm/Hyprland/releases/tag/v0.55.0
- Home Manager hyprland module at repo pin `2c0350c759688177331b8f5242311fae8877bdb3`:
  `modules/services/window-managers/hyprland/default.nix` (configType, assertions,
  reloadConfig, .luarc.json) and `.../lib.nix` (lua rendering rules)
  https://github.com/nix-community/home-manager/tree/2c0350c759688177331b8f5242311fae8877bdb3/modules/services/window-managers/hyprland
- nixpkgs package versions: search.nixos.org for `hyprland` (0.56.2 unstable,
  0.55.4 nixos-26.05), `stylua` 2.5.2, `selene` 0.31.0, `lua54Packages.luacheck` 1.2.0-1,
  `lua-language-server` 3.19.1, `lua5_5` 5.5.0
- nixos-rebuild(8) for `test`, `--rollback`, profile semantics
- Empirical tests on `nixos-desktop`, 2026-09-12: `--verify-config` exit codes for valid,
  invalid, and legacy hyprlang configs; sandbox run of `--verify-config`; live `hyprctl
  configerrors`, `getoption`, `binds -j` (46 binds)
