# PROTOTYPE: Hyprland Lua semantic parity comparator

Prototype for [Design the Hyprland Lua semantic parity harness](https://github.com/fveracoechea/dotfiles/issues/32) (map: Migrate the Hyprland module to native Lua). Throwaway code that answers one question: can an ordered, record-level diff against the live baseline catch every bind drift that matters (flags, args, descriptions, order, duplicates, missing records, submap/keycode/catch-all placement), with no count-based parity anywhere?

The build of the real gate belongs to [Build the Hyprland Lua verification harness](https://github.com/fveracoechea/dotfiles/issues/36). Nothing here is production code.

## Run it

```sh
nix build nixpkgs#lua5_5  # Lua 5.5, the interpreter version Hyprland 0.55.4 embeds
./result/bin/lua prototype/hyprland-parity/proto-parity.lua
```

## Files

- `proto-parity.lua`: the comparator. Decodes the live baseline with the vendored decoder, canonicalizes records, diffs positionally, then runs nine negative mutations that must each be detected.
- `proto-expected.lua`: the fixed expected subset. Six canonical bind records hand-copied from the live capture, chosen to cover the hard cases: trailing-comma arg, no-arg dispatcher, two-mod bind, duplicate key with different description, multi-arg arg, mouse bind.
- `vendor/json.lua`: rxi/json.lua at v0.1.2 (sha256 b13df59b32c77db3bec7a1619280ea77ee5014e715ccffaa4876d857e3e9ab87), the same decoder family the data bridge decision picked.

## What the run proved

1. **Lua 5.5 plus rxi/json.lua v0.1.2 decodes the real baseline captures.** This is an external-interpreter decode only. It does not exercise Hyprland's embedded parser; that gate is the real `Hyprland --verify-config`/parser check with fixtures, which the build ticket owns. This prototype also does not satisfy the bridge decoder gate from the data bridge decision: that gate needs schema validation plus malformed-JSON and missing-field rejection fixtures. No such fixtures exist here.
2. **The canonical record shape works for both sides.** One record shape covers what `hyprctl binds -j` reports and what a stub-exec call log would produce: modmask, key, keycode, submap, catch_all, description, dispatcher, arg, and the eight flag booleans. The comparator is strict: args are verbatim, so `togglesplit,` keeps its trailing comma and `0 2` stays `0 2`.
3. **This sparse comparator needs a declared scope.** The expected list here pins a handful of fixed indices into the 46-record baseline. With fixed-index subset matching, a dropped record in the middle passes unnoticed because the remaining expected entries still match their pinned indices; only a trailing drop inside the subset is caught by comparison alone. The coverage check against the declared index set is what catches middle drops in this design. A production comparator with dense full coverage behaves differently: a middle drop shifts every later record and fails positionally, but a trailing drop still needs an explicit coverage assertion. Either way the gate must assert both directions: every expected record matches, and every live record is covered. Subsets must be declared, never implied by counting.
4. **Full production record coverage is mandatory.** The prototype record carries every field `hyprctl binds -j` emits for this baseline. The build ticket must keep that property and re-check it whenever Hyprland adds bind fields; a canonical record that silently drops a field is a parity hole.
5. **Lua keyword collision.** `repeat` in `binds.json` is a reserved word in Lua 5.4/5.5, so record fields need bracket-quoted keys (`["repeat"]`). Trivial, but it would have bitten the build ticket.
6. **Live and disk bind order agree.** All 45 `bindd` entries in `generated/hyprland.conf` match the 45 keyboard records in `binds.json` one for one, in order (the mouse bind is last in both). The live capture is still the oracle because the conf proves generation, not loading.

## Design this feeds (for the build ticket)

Pipeline, cheapest to most human:

1. **Live facts, the parity oracle.** `hyprctl/options.json`, `hyprctl/binds.json`, `hyprctl/workspacerules.json` from the live capture. Binds compare as ordered canonical records with coverage both ways. Options compare by option name over the exact set (extra or missing option is a failure), with a typed normalizer registry because `getoption` returns normalized values (`gaps_out` becomes `"10 18 18 18"`, `single_window_aspect_ratio` becomes vec2 `[16, 9]`, `mfact` becomes `0.320000`). Workspace rules compare as ordered records.
2. **Disk evidence, byte level.** Window rules, `env` entries, monitor spec strings, and the user `exec-once` have no live dump in 0.55.4. These compare as ordered verbatim strings against `generated/hyprland.conf`. This proves what Home Manager generated, not what the session loaded; the live cross-checks (empty `configerrors`, agreeing `getoption` values) support but do not prove it. State this limit in the check output.
3. **Monitor live facts.** `monitors.json` asserts connector names and enabled/disabled state (`DP-1` enabled, `HDMI-A-1` disabled); its runtime fields are observations, not assertions. Whatever representation the hand-written config ends up using for monitors, the parity requirement is byte-exact spec semantics; whether that arrives as typed `hl.monitor` tables or a keyword passthrough is interface design still pending and does not change the assertion.
4. **User-only gates.** Lock/unlock, idle suspend, Sunshine monitor toggles, Steam Session, uwsm launch. Listed as a manual checklist, never automated.

## Seam context the harness inherits

The user set the seam: hand-written Lua lives as store-backed native modules following the actual Neovim precedent, with Home Manager generating the entry file and loader hooks. There is no public reload command to lean on, so the harness cannot depend on one; reload behavior belongs to the seam design, and the live gate works from what activation produces on disk plus the running session's `hyprctl` facts.

## Evidence gaps (explicit, unresolved)

1. **The Lua-call-to-record producer does not exist yet.** The comparator's expected records are hand-written canonical records. The production gate needs a stub-exec run of the real Lua config producing the same records, and nothing today proves that step. Marked gap, not a mocked success.
2. **Dispatcher call shapes from issue 31 are documented but not live-verified.** The 0.55 research gives `hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("..."), { release = true, ... })`, table-arg dispatchers (`hl.dsp.focus({ direction = "u" })`), mouse binds via `hl.dsp.window.drag()` / `hl.dsp.window.resize()`, and `hl.dsp.global` reserved for DBus global shortcuts. How a Lua-registered bind reappears in `hyprctl binds -j` (internal dispatcher name, arg reassembly like `"CTRL, INSERT, activewindow"`, modmask derived from `"SUPER + CTRL"` keys strings, call order) is unverified. Verify from the Hyprland 0.55.4 source dispatcher registry first, then confirm once in the user's live gate; no guessed mappings in the meantime.
3. **Monitor representation.** Typed `hl.monitor` tables versus keyword passthrough is undecided interface design (see the seam tickets); the harness design only fixes the assertion: byte-exact spec semantics.
4. **Bridge decoder gate fixtures.** Schema validation, malformed-JSON rejection, and missing-field rejection (data bridge decision: no invented defaults) are build-ticket work; this prototype decodes captures and nothing more.

## Status

Approved by the user on 2026-09-12 as the parity contract for the build ticket. The approved design:

- ordered binding records including duplicates, flags, keycodes, submaps, descriptions, and args, with coverage both ways (missing and extra records both fail)
- typed option comparison with normalization
- window rules, env, startup, and monitor specs compared against the captured config
- real Lua config run through the pinned Hyprland parser
- dispatcher mappings verified from the Hyprland 0.55.4 source, no guesses
- a final user session gate for behavior
- full implementation also carries bridge invalid/missing/schema fixtures and companion/System ownership fixtures

This comparator is method evidence only, not the completed gate. The build ticket ([Build the Hyprland Lua verification harness](https://github.com/fveracoechea/dotfiles/issues/36)) owns the real one.
