# Live Hyprland hyprlang behavior baseline

Snapshot of the running Hyprland 0.55.4 session on `nixos-desktop`, captured on 2026-09-12 for [Capture the live hyprlang behavior baseline](https://github.com/fveracoechea/dotfiles/issues/35). The later parity checks compare hand-written Lua behavior against this baseline, so it records what the compositor actually parsed and ran, not just what the Nix sources say.

## How this was captured

`scripts/capture-hyprland-baseline.sh` ran read-only `hyprctl` inspection commands and copied the Home-Manager-generated configs. It never dispatched, reloaded, locked, or mutated compositor state. To re-run:

```sh
scripts/capture-hyprland-baseline.sh test            # self-tests against a synthetic fixture
scripts/capture-hyprland-baseline.sh capture <dir>   # live capture, requires a Hyprland session
scripts/capture-hyprland-baseline.sh validate <dir>  # shape and sanitization checks
```

## Evidence classification

The migration needs to know what each file proves. Three kinds of evidence live here.

**Configuration evidence: what the parser holds.** `hyprctl/options.json` records 23 live `getoption` results from the parity checklist, all with `set: true`. `hyprctl/binds.json` records all 46 bindings with every flag (`locked`, `release`, `repeat`, `longPress`, `non_consuming`, `auto_consuming`, `mouse`, `has_description`), modmask, submap, dispatcher, argument, and description. `hyprctl/workspacerules.json` records the 5 persistent workspace rules. `hyprctl/configerrors.json` is `[""]`, the 0.55.4 representation of no errors. `generated/*.conf` are byte copies of the effective hyprlang files Home Manager generated, with one exception noted under sanitization.

**Observed behavior: what the session was doing at capture time.** `hyprctl/monitors.json` mixes the two kinds. `name`, `width`, `height`, `refreshRate`, `scale`, `transform`, `currentFormat`, and `colorManagementPreset` reflect the applied monitor config; `focused`, `dpmsStatus`, `vrr`, `activeWorkspace`, and `reserved` are runtime state. A concrete example of the difference: `misc:vrr` is `2` in options.json (configuration), while the monitor's `vrr` field is `false` (nothing was fullscreen at capture time). `observed/companion-processes.txt` lists process names and counts, and `observed/systemd-user-units.txt` lists unit names and states. Neither records argv or PIDs.

**Source cross-check.** The captured evidence matches the audit in `docs/research/current-hyprland-configuration-audit.md` and the Nix sources:

- 46 bindings = 27 fixed `bindd` + 18 generated workspace `bindd` + 1 `bindm` (`SHIFT_ALT, mouse:272, movewindow`, live modmask 9)
- all 45 `bindd` entries carry descriptions, including the 18 generated workspace bindings
- 16 `env` entries, 9 `windowrule` entries, 5 persistent workspaces, one user `exec-once` (`ultrashell`) plus the HM session-integration boilerplate
- `general:gaps_out` is `"10 18 18 18"` live, matching the source string `"10,18,18,18"` after normalization
- `general:col.active_border` is `ff89b4fa fff2cdcd 90deg` live, the blue and flamingo palette colors
- `layout:single_window_aspect_ratio` normalizes the source string `"16 9"` to the vec2 `[16, 9]`
- `master:mfact` is `0.320000` live from source `0.32`
- the monitor resolved `DP-1, 5120x1440@119.98` with `colorManagementPreset: srgb` from the host spec's `cm, auto`

One consequence for parity checks: `getoption` returns normalized values, not the conf text. Parity assertions must compare normalized forms, or diff against `generated/hyprland.conf` for byte-level claims.

## Untested checks (user-only)

These were deliberately not exercised, because testing them changes session state or needs the human at the desk:

- lock screen appearance and unlock (hyprlock was not running at capture, as expected)
- idle suspend path through hypridle's 900 s and 1800 s listeners
- Sunshine enable/disable monitor toggles, which call `hyprctl keyword` and would have mutated monitor state
- the Steam Session on the Dummy Plug (HDMI-A-1 gamescope output)
- uwsm session launch through Ly
- any reload or rebuild

## Gaps and limitations

- 0.55.4 has no `hyprctl windowrule` dump. Windowrule evidence comes from the generated conf file, not from the live parser's internal rule state. A parse check of that file against the live session exists only indirectly: the session loaded this exact file, and `configerrors` reports none.
- `configerrors` is coarse. It returns one empty string rather than a structured error list, so it cannot distinguish error kinds.
- `monitors.json` drops `id`, `serial`, and `description` per sanitization policy. The description string (which embeds the serial) is not preserved byte-identically anywhere.
- Store path hashes in the conf copies are replaced with `<hash>`. Only line 1 of `hyprland.conf` was affected (the HM dbus session integration); every config-relevant line is untouched.
- Process observations use truncated comm names (`.ultrashell-wrapped`), and child processes of the wrapper were not enumerated. The capture proves presence, not the full process tree.
- Companion configs are captured as files, not as running behavior. hypridle and hyprpaper were running when captured; their runtime behavior (timers, wallpaper drawing) is untested here.
- The capture is one point in time. It reflects the session as of 2026-09-12 with no fullscreen windows and HDMI-A-1 disabled.
