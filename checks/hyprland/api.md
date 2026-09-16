# Verified Hyprland 0.55.4 Lua API surface

Every claim here was read from the pinned source tag `v0.55.4`
(nixos-26.05 ships it; repo pin, ADR-0007). Source tree referenced from
a clone of `github.com/hyprwm/Hyprland` at that tag. Research prose was
NOT trusted; where earlier docs guessed wrong, this file states the
correction. Anything not listed here is unsupported by the parity
harness: the stub rejects it, and the port must not call it.

## Registration sites

- Toplevel functions: `src/config/lua/bindings/LuaBindingsToplevel.cpp`,
  `registerToplevelBindings`: `hl.on`, `hl.bind`, `hl.define_submap`,
  `hl.timer`, `hl.dispatch`, `hl.version`, `hl.exec_cmd`, `hl.unbind`.
- Config rules: `src/config/lua/bindings/LuaBindingsConfigRules.cpp`,
  `registerConfigRuleBindings`: `hl.config`, `hl.get_config`, `hl.device`,
  `hl.monitor`, `hl.window_rule`, `hl.layer_rule`, `hl.workspace_rule`,
  `hl.env`, `hl.permission`, `hl.plugin.load`, `hl.gesture`, `hl.curve`,
  `hl.animation`.
- Dispatcher table: `src/config/lua/bindings/LuaBindingsDispatchers.cpp`,
  `registerDispatcherBindings`.
- Event names: `src/config/lua/LuaEventHandler.cpp`, `knownEvents()`
  (includes `hyprland.start`, `hyprland.shutdown`).

## Binds

`hl.bind(keys, dispatcher, opts?)` (LuaBindingsToplevel.cpp `hlBind`):

- `keys` is one string, `+`-separated: modifiers first
  (`parseKeyString`: "Modifiers must come first in the list"). Mod names
  and bit values from `src/devices/IKeyboard.hpp`: SHIFT 1, CAPS 2,
  CTRL/CONTROL 4, ALT/MOD1 8, MOD2 16, MOD3 32, SUPER/WIN/LOGO/MOD4/META
  64, MOD5 128. These match the live baseline's modmask values (64 for
  SUPER, 68 SUPER+CTRL, 72 SUPER+ALT, 65 SUPER+SHIFT, 9 SHIFT+ALT).
- Key forms: keysym names (xkb, case-insensitive; `Enter` is rejected
  with a "did you mean Return?" hint), `code:N` (raw keycode),
  `mouse:N`, `mouse_down/up/left/right`, `switch:*`. `catchall` is a
  key string and is only legal inside a submap.
- `dispatcher` must be a dispatcher object built by a `hl.dsp.*`
  constructor, or a Lua function. A plain string is rejected:
  "hl.bind: dispatcher must be a dispatcher (e.g.
  hl.dsp.window.close()) or a lua function". The earlier research doc's
  example of a rejected string dispatcher is confirmed by source.
- `opts` booleans: `repeating`, `locked`, `release`, `non_consuming`,
  `auto_consuming`, `transparent`, `ignore_mods`, `dont_inhibit`,
  `long_press`, `submap_universal`, `click`, `drag`. Strings:
  `description` or `desc`. Devices: `device = { inclusive?, list }`.
  Source-verified constraints: `click`/`drag` exclusive; `long_press`/
  `release` incompatible with `repeating`; mouse is exclusive with
  repeat/release/locked.

**Divergence (verified, not normalized away in the live gate):** the
hyprlang path derives the `mouse` flag from the `bindm` keyword
(legacy `ConfigManager.cpp`, `case 'm'`), but the Lua `hl.bind` path
never assigns `kb.mouse` (no assignment in LuaBindingsToplevel.cpp), so
`hyprctl binds -j` reports `"mouse": false` for a Lua-config mouse bind
while the handler still runs. The parity gate normalizes the flag from
the key prefix on both sides and documents it; the user session gate
re-checks the live values.

**Divergence:** under a Lua config every bind is stored with
`handler = "__lua"` and `arg = <registry ref>` (LuaBindingsToplevel.cpp
`hlBind`), so `hyprctl binds -j` reports `dispatcher: "__lua"` for all
of them. Live-dispatcher names therefore come from the mapping table
below, not from a live dump.

## Dispatcher mapping table (legacy vocabulary)

What each verified `hl.dsp.*` constructor means in the `hyprctl binds
-j` dispatcher/arg vocabulary of the old config. The parity comparator
rebuilds the legacy pair from the constructor arguments; forms without
a legacy equivalent are rejected, not guessed.

| hl.dsp call                                   | legacy (dispatcher, arg)        | Source |
|-----------------------------------------------|--------------------------------|--------|
| `window.close()`                              | `killactive`, ""               | both call `Actions::closeWindow` |
| `window.float()`                              | `togglefloating`, ""           | both `Actions::floatWindow(TOGGLE)` |
| `window.fullscreen()`                         | `fullscreen`, "0"              | `FSMODE_FULLSCREEN`, toggle |
| `window.fullscreen{mode="maximized"}`         | `fullscreen`, "1"              | `FSMODE_MAXIMIZED` |
| `window.fullscreen{action="set"/"unset"}`     | unsupported (no legacy arg)    | rejected by the comparator |
| `window.fullscreen_state{internal=I, client=C}` | `fullscreenstate`, "I C"     | both `Actions::fullscreenWindow(im, cm)` |
| `window.pseudo()`                             | `pseudo`, ""                   | both `Actions::pseudoWindow(TOGGLE)` |
| `window.resize{x=X, y=Y, relative=true}`      | `resizeactive`, "X Y"          | `Actions::resize(size, true)`; legacy computes the same delta via `parseWindowVectorArgsRelative` for these args |
| `window.drag()`                               | `mouse`, "movewindow"          | both `Actions::mouse("movewindow")` |
| `window.move{workspace=W}`                    | `movetoworkspace`, W           | both `Actions::moveToWorkspace(ws, false, active)` |
| `window.move{workspace=W, follow=false}`      | `movetoworkspacesilent`, W     | silent = `follow == false` |
| `group.toggle()`                              | `togglegroup`, ""              | both `Actions::toggleGroup` |
| `focus{direction=D}`                          | `movefocus`, D                 | both `Actions::moveFocus(dir)`; parseDirectionStr accepts l/r/u/d and left/right/up/down |
| `focus{workspace=W}`                          | `workspace`, W                 | both `Actions::changeWorkspace`; "previous", "e+1", "e-1" handled by `resolveWorkspaceForChange`/`getWorkspaceIDNameFromString` (ConfigActions.cpp) |
| `exec_cmd(CMD)`                               | `exec`, CMD (verbatim)         | both spawn through the executor |
| `send_shortcut{mods=M, key=K, window=W}`      | `sendshortcut`, "M, K, W"      | both `Actions::pass(mods, keycode, window)` |
| `layout(MSG)`                                 | `layoutmsg`, MSG (verbatim)    | both `Actions::layoutMessage`; the baseline's trailing comma is part of the arg |

Unsupported by this mapping (rejected): `window.fullscreen_state`
without internal/client or with action toggle/unset, `window.move`
spatial/monitor/group forms except `out_of_group=true`, `focus` monitor/window/urgent selectors,
`send_shortcut` without a window, any field the table above does not
list for a constructor.

### Recorder restrictions

The table above describes supported legacy equivalents, not all raw API forms.
`window.move{out_of_group=true}` additionally maps to `moveoutofgroup`, empty
argument. Source: `LuaBindingsDispatchers.cpp:870-875` and
`DispatcherTranslator.cpp:734-739`. A coverage test checks every dispatcher
name in the current captured binds against a supported constructor.

The recorder rejects all window selectors except the required selector in
`send_shortcut`. It also rejects `focus.on_current_monitor`, execution-rule
arguments to `exec_cmd`, extra positional arguments, ambiguous move forms,
and unsupported field names or types. `relative` must be boolean true for
resize. Workspace selectors use strings; directions use `l`, `r`, `u`, `d`.

Only single-key binds, keycodes, special keys, and catchall are recorded.
Chords, function dispatchers, submap reset extensions, and unmodeled bind
options are rejected. Supported options are `description`/`desc`, `locked`,
`release`, `repeating`, `non_consuming`, `auto_consuming`, and `long_press`.
Flag values must be booleans. Release or long-press cannot combine with repeat.
Input tables are copied when recorded, as the real parser consumes their
values at the call rather than observing subsequent Lua mutations.

## Options

- `hl.config{...}`: nested tables flatten with DOTS
  (`LuaBindingsConfigRules.cpp hlConfig` walk: `prefix .. '.' .. key`).
  The colon form (`general:gaps_in`) is the hyprctl query syntax;
  `CConfigManager::luaConfigValueName` maps ':' to '.' and '-' to '_'
  (ConfigManager.cpp). **Correction to earlier research prose:** the
  generated-key separator is '.', not ':'.
- A registered option key parses its value directly, tables included;
  only unregistered keys recurse into nested tables (hlConfig walk).
- Typed values the config uses (types in `src/config/lua/types/`):
  - CSS gap (`LuaConfigCssGap.cpp`): an integer or a table with optional
    `top`, `right`, `bottom`, `left`. A comma string is rejected by the
    parser ("css_gap type requires an integer or a table..."); the
    parser gate caught exactly this when first run.
  - Gradient (`LuaConfigGradient.cpp`): a color string or a table
    `{ colors = { "rgb(...)", ... }, angle = N }`.
  - getoption normalization: gaps become the four-value string
    ("10 10 10 10"), booleans report as int 1/0, colors report as
    `ffRRGGBB` tokens plus the angle in degrees. The registry in
    `records.lua` encodes the captured oracle
    (`docs/research/hyprland-live-baseline/hyprctl/options.json`).

## Monitors

`hl.monitor{ output = "...", ... }`: typed fields from
`MONITOR_FIELDS` (LuaBindingsConfigRules.cpp): `mode`, `position`,
`scale`, `reserved`/`reserved_area`, `disabled`, `transform`, `mirror`,
`bitdepth`, `cm`, `sdr_eotf`, `sdrbrightness`, `sdrsaturation`, `vrr`,
`icc`, `supports_wide_color`, `supports_hdr`, `sdr_min_luminance`,
`sdr_max_luminance`, `min_luminance`, `max_avg_luminance`,
`max_luminance`. `output` is required; unknown fields are config
errors. The legacy spec grammar it must match:
`NAME, MODE, POSITION, SCALE, [key, value]*` or the short forms
`NAME, disable|disabled`, `NAME, transform, N`,
`NAME, addreserved, T, R, B, L` (legacy ConfigManager.cpp
`handleMonitor`); key set: mirror, bitdepth, cm, sdrsaturation,
sdrbrightness, transform, vrr, icc.

## Window rules

`hl.window_rule{ name?, enabled?, match = { <prop> = <value> }, <effect> = <value> }`.
Effect names from `WINDOW_RULE_EFFECT_DESCS`
(LuaBindingsInternal.hpp); match props from `MATCH_PROP_STRINGS`
(src/desktop/rule/Rule.cpp): class, title, initial_class,
initial_title, float, tag, xwayland, fullscreen, pin, focus, group,
modal, fullscreen_state_internal, fullscreen_state_client, workspace,
content, xdg_tag, namespace. Effects not in the static list go through
the dynamic effect registry; the stub does not model those and rejects
them.

Repeated nonempty names are rejected. The real API reuses a named rule object
(`LuaBindingsConfigRules.cpp:1089-1096`); the recorder compares independent
rules and does not model updates to existing objects.

## Workspace rules

`hl.workspace_rule{ workspace = "...", ... }`: `workspace` is required
(hlWorkspaceRule); other fields from `WORKSPACE_RULE_FIELDS`:
monitor, default, persistent, gaps_in, gaps_out, float_gaps,
border_size, no_border, no_rounding, decorate, no_shadow,
on_created_empty, default_name, layout, animation, plus `layout_opts`.

The parity comparator supports only the captured `workspace` and `persistent`
fields, with `enabled` omitted or true. Other Lua or baseline fields fail
rather than being ignored. This is a deliberate subset of the raw API.

## env, startup, events

- `hl.env(name, value, dbus?)` sets the variable immediately
  (LuaBindingsConfigRules.cpp `hlEnv`).
- **There is no `exec-once` API on the Lua surface.** The only internal
  `addExecOnce` callers reachable from config are the legacy handlers
  and `hlEnv`'s dbus path. The port must express startup through
  `hl.on("hyprland.start", ...)` (a known event). Config-level commands
  are recorded but fail parity because they also execute on reload.
- `hl.on(event, fn)` with the event set from `knownEvents()`; unknown
  names are config errors.

The production capture runs only start and shutdown callbacks, permits only
commands in those callbacks, and rejects other events at comparison time.
The read-only Lua loader and command recording contract are in README.md.
The third `hl.env` argument and second `hl.exec_cmd` argument are unsupported
in capture, rather than silently ignored.
