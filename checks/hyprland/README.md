# Hyprland Lua verification harness

The automated gates for the native Lua compositor configuration, built
before the port in [Build the Hyprland Lua verification harness](https://github.com/fveracoechea/dotfiles/issues/36).
The approved [parity design](https://github.com/fveracoechea/dotfiles/issues/32)
and [Home Manager seam](https://github.com/fveracoechea/dotfiles/issues/34)
define the contract.

## Checks

All wired into `checks` in `flake.nix` and run by `nix flake check`:

| Check | What it does |
|---|---|
| `hyprland-lua-static` | stylua, luacheck, Lua 5.5 syntax (`luac -p`) on the harness and, once present, `config/hypr` |
| `hyprland-bridge-tests` | bridge contract under Lua 5.5: schema acceptance, every rejection case, decoder evidence |
| `hyprland-semantic-fixture` | the comparator pipeline in fixture mode: positive records, 10 negative bind mutations, typed options, disk evidence, and strict-mapping rejections |
| `hyprland-parser-fixture` | real `Hyprland --verify-config` at the pinned 0.55.4: valid fixture must parse; invalid-dispatcher and invalid-syntax fixtures must fail |
| `hyprland-repo-ownership` | Real repo module: companion and System package ownership, synthetic Home and monitor data, inert Darwin evaluation, and correct config-file ownership before and after the port |
| `hyprland-production-parity` | runs the staged Home Manager entry and production modules in the recording environment, then compares supported records and lifecycle commands against the baseline, with the approved shutdown exception below |
| `hyprland-production-parser` | parses the actual staged Home Manager entry, native modules, and generated JSON with Hyprland 0.55.4 |

The parser check uses the Release Channel compositor (`pkgs-stable.hyprland`, ADR-0007); the rest runs on the Latest Channel tools. Tests run on Lua 5.5, the interpreter version Hyprland 0.55.4 embeds.

## Run locally

```sh
nix build nixpkgs#lua5_5 -o /tmp/lua55
/tmp/lua55/bin/lua checks/hyprland/bridge-test.lua .
/tmp/lua55/bin/lua checks/hyprland/semantic-test.lua .
nix build .#checks.x86_64-linux.hyprland-parser-fixture
```

## Port contract

[Port the compositor configuration to native Lua](https://github.com/fveracoechea/dotfiles/issues/37)
supplies the production files.

The parity gate executes the production entry and compares against
`docs/research/hyprland-live-baseline/`:

1. Home Manager owns `hypr/hyprland.lua`, including its session hooks.
   Its user configuration loads `entry` from `config/hypr/entry.lua`.
   `entry` requires `bridge` first and applies modules in the fixed order
   from the seam decision. The recorder runs the Home Manager entry, not
   a replacement that skips its hooks.
   A final `require("lifecycle")` line in `extraConfig` loads user startup
   after Home Manager registers its hooks. The ownership check permits only
   that exact loader line, not arbitrary generated compositor settings.
2. `config/hypr/bridge.lua` loads `dotfiles/hyprland.json` from
   `$XDG_CONFIG_HOME` and validates before anything applies. The gate
   runs with `XDG_CONFIG_HOME` pointing at the real Home Manager sources,
   including its generated bridge file. The
   reference loader in `checks/hyprland/bridge.lua` is the executable
   contract; the port copies it (it already requires the decoder by its
   production module name `lib.json`).
3. `config/hypr/lib/json.lua` is the vendored rxi/json.lua v0.1.2 with
   documented changes in this directory's `lib/json.lua`. Preserve the
   MIT header. Null uses a sentinel and round-trips as null. The decoder
   rejects trailing commas, non-JSON number forms, invalid escapes,
   invalid UTF-8, unpaired surrogates, duplicate object keys, and numeric
   overflow. Valid surrogate pairs and escaped backslashes decode correctly.
4. Modules use only the recorder subset documented in `api.md`.
   Binds compare positionally against all 46 baseline records. Options
   compare the exact captured 23-option set. Workspace rules compare the
   five persistent rules and reject extra fields on either side. Env
   entries compare byte-for-byte in order. Monitor fields compare with
   the captured specification. Window effects and matches compare in
   both directions, and repeated nonempty rule names are rejected.
5. The dispatcher mapping is strict: calls without a verified legacy
   equivalent fail the gate instead of passing by construction. New
   dispatcher usage requires a source-verified mapping entry plus a
   mutation test here first.
6. The `mouse` flag divergence (hyprlang `bindm` sets it, the Lua path
   does not) is normalized from the key prefix and re-checked at the
   user session gate, which remains mandatory and user-run.

## Staging protocol

The coordinator invokes:

```sh
lua checks/hyprland/parity-test.lua REPO_ROOT STAGED_HYPRLAND_LUA DBUS_EXECUTABLE
```

- `REPO_ROOT/config/hypr/entry.lua` must exist. Absence remains an intentional failure.
- `STAGED_HYPRLAND_LUA` is the actual Home Manager generated entry, including
  its session hooks. Its directory contains the production `entry.lua`,
  other modules, and `lib/json.lua`. Use an absolute directory without `..`.
- Set `XDG_CONFIG_HOME` to the staged config home, containing Home Manager's
  generated `dotfiles/hyprland.json`. Set `HOME` deterministically if modules use it.
- `DBUS_EXECUTABLE` is the exact expected dbus-update-activation-environment
  executable path. It replaces only the redacted executable prefix in the
  captured startup command. Arguments and shell command suffixes are not normalized.
- The restricted loader resolves `require("name")` to `name.lua` within the
  staged directory, including dotted names. `dofile` stays in that directory.
  Native modules, external Lua modules, process reads, and file writes are unsupported.
- The recorder loads the entry once, then calls registered `hyprland.start`
  callbacks in registration order, followed by `hyprland.shutdown` callbacks.
  Callbacks may only issue commands. `hl.exec_cmd` and `os.execute` record
  strings without spawning processes. Simulated `os.execute` returns `true, "exit", 0`.
- Start and shutdown command lists compare exactly against `exec-once` and
  `exec-shutdown` in the captured config, with the one approved exception below.
  Missing, changed, reordered, or extra
  commands fail. Config-level commands and other event registrations fail.
  More than one callback for a lifecycle event is allowed so Home Manager
  hooks and user startup modules can register separately.
- `semantic-test.lua` also runs `lifecycle-test.lua`. No separate test wiring
  is needed for the controlled execution and lifecycle mutation tests.

## Approved shutdown exception

The user approved keeping the pinned Home Manager Lua shutdown hook in
[Port the compositor configuration to native Lua](https://github.com/fveracoechea/dotfiles/issues/37).
The captured hyprlang command, `systemctl --user stop hyprland-session.target`,
spawned asynchronously. Home Manager's Lua hook calls
`os.execute("systemctl --user stop hyprland-session.target && sleep 0.1")`.
It waits for the stop command and, if that succeeds, waits another 0.1 seconds.
This is an accepted behavior change, not exact lifecycle parity.

The comparator replaces only the single exact captured shutdown command with
that exact pinned Lua command. It does not edit the captured baseline, strip
suffixes, or relax startup order. Mutation tests reject a missing or changed
wait, another target, another shell operator, reordered or extra commands,
duplicate shutdown callbacks, a changed baseline command, and startup suffixes.
Source references and the loader-order reason are in `api.md`.

## Honest limits

- Env, monitor, window-rule, and startup parity is against the captured
  hyprlang config: what Home Manager generated, not what the session
  loaded. The live session gate (empty `configerrors`, agreeing
  getoption values, binds dump) closes that gap; it cannot be automated
  and stays with the user.
- The recorder deliberately rejects unsupported valid API extensions. It
  does not implement arbitrary Hyprland queries, bind callbacks, key chords,
  device restrictions, named-rule updates, or additional workspace fields.
- Lifecycle checks prove recorded command strings and their event placement,
  not successful process execution or systemd state. The recording environment
  is for trusted repository configuration, not hostile Lua. It has no host
  process API, but does not impose memory or execution-time limits.
- luacheck has no Lua 5.5 mode; `std = "lua54"` is the closest lint
  target and `luac -p` from `lua5_5` owns the syntax gate.
