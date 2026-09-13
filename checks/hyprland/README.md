# Hyprland Lua verification harness

The automated gates for the native Lua compositor configuration, built
before the port (map: Migrate the Hyprland module to native Lua, ticket
Build the Hyprland Lua verification harness). The parity design and its
approval live in issue 32; the seam contract lives in issue 34.

## Checks

All wired into `checks` in `flake.nix` and run by `nix flake check`:

| Check | What it does |
|---|---|
| `hyprland-lua-static` | stylua, luacheck, Lua 5.5 syntax (`luac -p`) on the harness and, once present, `config/hypr` |
| `hyprland-bridge-tests` | bridge contract under Lua 5.5: schema acceptance, every rejection case, decoder evidence |
| `hyprland-semantic-fixture` | the comparator pipeline in fixture mode: positive records, 10 negative bind mutations, typed options, disk evidence, and strict-mapping rejections |
| `hyprland-parser-fixture` | real `Hyprland --verify-config` at the pinned 0.55.4: valid fixture must parse; invalid-dispatcher and invalid-syntax fixtures must fail |
| `hyprland-ownership-fixture` | Home Manager at the flake pin: `configType = "lua"` generates `hypr/hyprland.lua` and never `hypr/hyprland.conf` |
| `hyprland-production-parity` | runs the production `config/hypr/entry.lua` under the recorder stub and compares everything against the live baseline capture. **Red until the port ticket lands**; that is intentional, so `nix flake check` cannot pass while hyprlang still owns the compositor |

The parser check uses the Release Channel compositor (`pkgs-stable.hyprland`, ADR-0007); the rest runs on the Latest Channel tools. Tests run on Lua 5.5, the interpreter version Hyprland 0.55.4 embeds.

## Run locally

```sh
nix build nixpkgs#lua5_5 -o /tmp/lua55
/tmp/lua55/bin/lua checks/hyprland/bridge-test.lua .
/tmp/lua55/bin/lua checks/hyprland/semantic-test.lua .
nix build .#checks.x86_64-linux.hyprland-parser-fixture
```

## Port contract (ticket 37)

The parity gate executes the production entry and compares against
`docs/research/hyprland-live-baseline/`:

1. `config/hypr/entry.lua` is the only autoload file; it requires
   `bridge` first and applies the modules in the fixed order from the
   seam decision. The gate runs it with the `hl` stub as global.
2. `config/hypr/bridge.lua` loads `dotfiles/hyprland.json` from
   `$XDG_CONFIG_HOME` and validates before anything applies. The gate
   runs with `XDG_CONFIG_HOME` pointing at a prepared bridge file. The
   reference loader in `checks/hyprland/bridge.lua` is the executable
   contract; the port copies it (it already requires the decoder by its
   production module name `lib.json`).
3. `config/hypr/lib/json.lua` is the vendored rxi/json.lua v0.1.2 with
   one documented deviation: `null` decodes to a `json.null` sentinel
   so explicit nulls are rejected instead of dropped (the data bridge
   decision requires visible rejection of malformed data with no
   invented defaults; upstream's nil mapping would hide them). Keep the
   MIT header and the deviation comment.
4. Modules record through the verified API surface in `api.md`:
   - binds as full ordered records: the gate compares all 46 baseline
     binds positionally, both ways, including duplicates, flags,
     keycodes, submaps, descriptions, and verbatim args;
   - options through `hl.config` with the typed Lua forms (gap tables,
     gradient tables); the gate compares the exact 23-option set with
     the captured getoption normalization;
   - workspace rules against `workspacerules.json` (5 persistent rules);
   - env entries byte-level against the captured `env=` lines;
   - monitors with the fields the legacy spec states; the comparator
     parses the legacy line and compares every explicit field plus
     factory defaults;
   - window rules two-way against the captured `windowrule=` lines
     (effect, value, and every match property in both directions);
   - startup via `hl.on("hyprland.start")`; the Lua API has no
     exec-once (see api.md).
5. The dispatcher mapping is strict: calls without a verified legacy
   equivalent fail the gate instead of passing by construction. New
   dispatcher usage requires a source-verified mapping entry plus a
   mutation test here first.
6. The `mouse` flag divergence (hyprlang `bindm` sets it, the Lua path
   does not) is normalized from the key prefix and re-checked at the
   user session gate, which remains mandatory and user-run.

## Honest limits

- Env, monitor, window-rule, and startup parity is against the captured
  hyprlang config: what Home Manager generated, not what the session
  loaded. The live session gate (empty `configerrors`, agreeing
  getoption values, binds dump) closes that gap; it cannot be automated
  and stays with the user.
- The pinned decoder still accepts trailing commas and leading zeros;
  the schema validation is the strictness layer on top. This is
  documented evidence, not a strict-JSON claim.
- luacheck has no Lua 5.5 mode; `std = "lua54"` is the closest lint
  target and `luac -p` from `lua5_5` owns the syntax gate.
