# PROTOTYPE: Hyprland Lua semantic parity comparator

Prototype for [Design the Hyprland Lua semantic parity harness](https://github.com/fveracoechea/dotfiles/issues/32) (map: Migrate the Hyprland module to native Lua). Throwaway code that answers one question: can an ordered, record-level diff against the live baseline catch every bind drift that matters (flags, args, descriptions, order, duplicates, missing records), with no count-based parity anywhere?

The build of the real gate belongs to [Build the Hyprland Lua verification harness](https://github.com/fveracoechea/dotfiles/issues/36). Nothing here is production code.

## Run it

```sh
nix build nixpkgs#lua5_5  # Lua 5.5, the interpreter Hyprland 0.55.4 embeds
./result/bin/lua prototype/hyprland-parity/proto-parity.lua
```

## Files

- `proto-parity.lua`: the comparator. Decodes the live baseline with the vendored decoder, canonicalizes records, diffs positionally, then runs six negative mutations that must each be detected.
- `proto-expected.lua`: the fixed expected subset. Six canonical bind records hand-copied from the live capture, chosen to cover the hard cases: trailing-comma arg, no-arg dispatcher, two-mod bind, duplicate key with different description, multi-arg arg, mouse bind.
- `vendor/json.lua`: rxi/json.lua at v0.1.2 (sha256 b13df59b32c77db3bec7a1619280ea77ee5014e715ccffaa4876d857e3e9ab87), the same decoder family the data bridge decision picked.

## What the run proved

1. **The decoder gate works on the embedded interpreter.** Lua 5.5.0 plus rxi/json.lua v0.1.2 decodes the real `binds.json` (46 records) with no patches. This is the same pairing the data bridge decision requires for the JSON bridge.
2. **The canonical record shape works for both sides.** One record shape covers what `hyprctl binds -j` reports and what a stub-exec call log would produce: modmask, key, description, dispatcher, arg, and all eight flag booleans. The comparator is strict: args are verbatim, so `togglesplit,` keeps its trailing comma and `0 2` stays `0 2`.
3. **Missing records need a declared scope.** A dropped record never mismatches positionally; the comparator only catches it by checking coverage of a declared index set. The production gate must assert both directions: every expected record matches, and every live record is covered. Subsets must be explicit, never implied by counting.
4. **Lua keyword collision.** `repeat` in `binds.json` is a reserved word in Lua 5.4/5.5, so record fields need bracket-quoted keys (`["repeat"]`). Trivial, but it would have bitten the build ticket.
5. **Live order differs from disk order.** The generated `hyprland.conf` lists `Copy` among the fixed binds, but in live registration order it sits at index 26. The live capture, not the conf file, is the order oracle.

## Design this feeds (for the build ticket)

Pipeline, cheapest to most human:

1. **Live facts, the parity oracle.** `hyprctl/options.json`, `hyprctl/binds.json`, `hyprctl/workspacerules.json` from the live capture. Binds compare as ordered canonical records with coverage both ways. Options compare by option name over the exact set (extra or missing option is a failure), with a typed normalizer registry because `getoption` returns normalized values (`gaps_out` becomes `"10 18 18 18"`, `single_window_aspect_ratio` becomes vec2 `[16, 9]`, `mfact` becomes `0.320000`). Workspace rules compare as ordered records.
2. **Disk evidence, byte level.** Window rules, `env` entries, monitor spec strings, and the user `exec-once` have no live dump in 0.55.4. These compare as ordered verbatim strings against `generated/hyprland.conf`. This proves what Home Manager generated, not what the session loaded; the live cross-checks (empty `configerrors`, agreeing `getoption` values) support but do not prove it. State this limit in the check output.
3. **Monitor live facts.** `monitors.json` asserts connector names and enabled/disabled state (`DP-1` enabled, `HDMI-A-1` disabled); its runtime fields are observations, not assertions.
4. **User-only gates.** Lock/unlock, idle suspend, Sunshine monitor toggles, Steam Session, uwsm launch. Listed as a manual checklist, never automated.

## Evidence gaps (explicit, unresolved)

1. **The Lua-call-to-record producer does not exist yet.** The comparator's expected records are hand-written canonical records. The production gate needs a stub-exec run of the real Lua config producing the same records, and nothing today proves that step. Marked gap, not a mocked success.
2. **Dispatcher call shapes from issue 31 are documented but not live-verified.** The 0.55 research gives `hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("..."), { release = true, ... })`, table-arg dispatchers (`hl.dsp.focus({ direction = "u" })`), mouse binds via `hl.dsp.window.drag()` / `hl.dsp.window.resize()`, and `hl.dsp.global` reserved for DBus global shortcuts. How a Lua-registered bind reappears in `hyprctl binds -j` (internal dispatcher name, arg reassembly like `"CTRL, INSERT, activewindow"`, modmask derived from `"SUPER + CTRL"` keys strings, call order) is unverified. Verify from the Hyprland 0.55.4 source dispatcher registry first, then confirm once in the user's live gate; no guessed mappings in the meantime.
3. **Monitor spec re-shaping.** The host monitor strings must become typed `hl.monitor` tables; the reverse mapping (table back to the byte-exact spec string for the disk diff) is undecided and belongs to the seam design ticket.

## Status

Awaiting user approval through the coordinator. If approved, capture this directory on its prototype branch as the primary source for the build ticket.
