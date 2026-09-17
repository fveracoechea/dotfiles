# Hyprland configuration and migration

The compositor configuration is hand-written Lua in [`config/hypr/`](../config/hypr/).
It targets the pinned Hyprland 0.55.4 and its Lua 5.5 API.
This migration does not update the Release Channel or verify later Hyprland versions.

## Ownership and installation

| Owner | Configuration |
| --- | --- |
| [System Module](../modules/nixos/hyprland.nix) | Release Channel compositor and portal, XWayland, UWSM session integration, graphics, Bluetooth, and System session variables |
| [Home Manager Module](../modules/home-manager/hyprland/settings.nix) | Store-backed Lua installation, generated entry, JSON bridge, internal activation reloads, and upstream systemd hooks |
| [Native entry](../config/hypr/entry.lua) | Bridge validation and ordered application of settings, environment, bindings, window rules, and Theme |
| [Native lifecycle](../config/hypr/lifecycle.lua) | Ultrashell startup after the upstream session hook, only if the native entry succeeded |
| [Companion modules](../modules/home-manager/hyprland/) | Hypridle, Hyprlock, Hyprpaper, and cursor configuration, still managed by Home Manager in their own formats |

Enable `dotfiles.hyprland.enable` in both the System and Home contexts.
Home Manager sets `package = null` and `portalPackage = null` because the System owns those packages.
The compositor and its Version-Coupled Packages remain on the Release Channel, as defined in [ADR-0007](adr/0007-split-nixpkgs-channels-by-package-owner.md).
Ultrashell keeps its own input revision and builds its Hyprland dependencies on that channel.

The install follows the actual [Neovim module](../modules/home-manager/neovim.nix) and [Config Directory decision](adr/0005-non-nix-config-in-top-level-config-directory.md).
Home Manager copies repository source into the Nix store and installs links to those store files.
It does not use out-of-store links or a checkout path option.
Editing `config/hypr/` takes effect after a rebuild and activation, not immediately.

`configType = "lua"` is explicit, and `settings = {}` stays empty.
The generated `$XDG_CONFIG_HOME/hypr/hyprland.lua` contains only Home Manager's session hooks and module-loading code.
Nix must not generate native compositor settings.
Home Manager installs each native file through `extraLuaFiles`; dotted names map to subdirectories, such as `modules.settings` to `hypr/modules/settings.lua`.
Only `entry` has `autoLoad = true`.
The production file set contains `hyprland.lua`, not `hyprland.conf`.
The config-type change and native sources landed together.

## Bridge and lifecycle

Home Manager generates `$XDG_CONFIG_HOME/dotfiles/hyprland.json`, outside the `hypr/` directory.
The [bridge loader](../config/hypr/bridge.lua) uses `$HOME/.config` when `XDG_CONFIG_HOME` is unset or empty.
This is the desktop data shape, not a second file to maintain by hand:

```json
{
  "monitors": [
    "DP-1, 5120x1440@119.98Hz, auto, auto, bitdepth, 8, cm, auto",
    "HDMI-A-1, disable"
  ],
  "theme": {
    "blue": "#89B4FA",
    "flamingo": "#F2CDCD",
    "surface2": "#585B70"
  },
  "paths": {
    "fuzzelCache": "/home/fveracoechea/.config/fuzzel/cache"
  }
}
```

| Field | Source and validation |
| --- | --- |
| `monitors` | `config.dotfiles.hyprland.monitors`, an array of up to 64 non-empty spec strings; `[]` is valid and declares no monitors; objects and JSON null are rejected |
| `theme.blue`, `theme.flamingo`, `theme.surface2` | `config.dotfiles.palette`, required raw `#RRGGBB` strings; Lua converts them to compositor colors |
| `paths.fuzzelCache` | `${config.home.homeDirectory}/.config/fuzzel/cache`, a required non-empty absolute path; Lua quotes it for the launcher command when needed |

The vendored decoder is based on rxi/json.lua v0.1.2, revision `d1e3b0f5d0f3d3493c7dadd0bb54135507fcebd7`.
Its MIT license, local strict-JSON changes, and array-type tracking are documented in [`config/hypr/README.md`](../config/hypr/README.md).
Missing files, malformed JSON, and invalid required fields report a configuration error rather than using fallback values.
The entry validates the bridge before it applies any native module, then applies settings, environment, bindings, window rules, and Theme in that order.

Home Manager registers its upstream start and shutdown hooks after loading `entry`.
The final generated line, `require("lifecycle")`, loads the hand-written startup module after those hooks.
That module requires the entry's explicit `true` result before registering Ultrashell startup.
This matters because Hyprland catches a failed `require` and caches an empty table instead of stopping the parent file.
An invalid bridge therefore blocks native configuration and user startup, but does not remove Home Manager's own hooks.

On startup, Home Manager launches its D-Bus/systemd environment update and session-target command before Lua launches `ultrashell`.
Both launches are asynchronous.
Their launch order is preserved, not their completion order.
The [user-approved shutdown exception](https://github.com/fveracoechea/dotfiles/issues/34#issuecomment-5713303720) keeps the upstream hook exactly:

```lua
os.execute("systemctl --user stop hyprland-session.target && sleep 0.1")
```

Unlike the old asynchronous shutdown command, this waits for the target stop and, on success, waits another 0.1 seconds.
The [API contract](../checks/hyprland/api.md#home-manager-lifecycle-order-and-approved-exception) records the source evidence.
The captured hyprlang baseline remains unchanged.

## Activation reloads

There is no public reload helper or command to install.
Two internal Home Manager `onChange` hooks use the same reload snippet:

- `dotfiles/hyprland.json` changes when bridge data changes.
- `dotfiles/hyprland.stamp` hashes all installed native Lua sources, so source-only edits also trigger a reload.

The snippet uses the Release Channel `hyprctl`, enumerates this user's instances, and performs a full `hyprctl -i <instance> reload` for each one.
It does not use `config-only` or depend on the activation shell having an instance signature.
`XDG_RUNTIME_DIR` falls back to `/run/user/$(id -u)`.
Zero instances is a no-op; enumeration or reload failures go to stderr without failing activation.
Inspect activation logs and live `configerrors`, even when the rebuild succeeds.
The stamp is needed because upstream Home Manager skips its generated-entry reload hook when `package = null`.

The initial language change still needs a fresh Hyprland session.
A successful activation reload is not proof that an existing hyprlang process has selected the new Lua entry.
Later source and bridge changes use the internal hooks; they do not relaunch Ultrashell as a config-level command.

## Desktop behavior

The [host](../hosts/nixos-desktop/home.nix) supplies both monitor strings shown above.
DP-1 is the Samsung Odyssey at 5120x1440 and 119.98 Hz.
HDMI-A-1, the Dummy Plug, starts disabled in Hyprland.
Lua converts the declared specs to typed `hl.monitor` calls.

- Dwindle layout, `preserve_split = true`, and `force_split = 2`.
- Border size 3, inner gaps 10, outer gaps top/right/bottom/left `10,18,18,18`, and border resizing enabled.
- Rounding 8 and blur enabled.
- VRR mode 2, animated manual resizing, and animated mouse dragging.
- Single-window aspect ratio `16 9`; master layout allows small splits, uses `mfact = 0.32`, and does not put new windows on top.
- Persistent workspaces 1 through 5, drag threshold 10, and workspace cycles allowed.
- Catppuccin Mocha active border from blue to flamingo at 90 degrees; inactive border uses surface2.
- Ultrashell is the only user startup command.

### Bindings

There are 45 described keyboard bindings and one mouse binding.
The [native bindings](../config/hypr/modules/bindings.lua) preserve their order and arguments.

| Key | Action |
| --- | --- |
| `SUPER + J` | Toggle split, also bound to focus down; existing overlap preserved |
| `SUPER + T` | Toggle floating/tiling |
| `SUPER + F` | Fullscreen |
| `SUPER + CTRL + F` | Tiled fullscreen, internal state 0 and client state 2 |
| `SUPER + ALT + F` | Full width |
| `SUPER + W` | Close active window |
| `SUPER + K/J/L/H` | Focus up/down/right/left |
| `SUPER + CTRL + K/J/L/H` | Resize active window by 100 pixels in that direction |
| `SUPER + P` / `SUPER + CTRL + P` | Toggle pseudo / all pseudo |
| `SUPER + G` / `SUPER + ALT + G` | Toggle grouping / move active window out of group |
| `SUPER + 1-9` / `SUPER + SHIFT + 1-9` | Focus workspace / move active window to workspace |
| `SUPER + TAB` / `SUPER + SHIFT + TAB` / `SUPER + CTRL + TAB` | Next / previous / former workspace |
| `SUPER + B` / `SUPER + S` | Google Chrome / Ghostty |
| `SUPER + A` | Fuzzel with the bridge's `--cache` path |
| `SUPER + O` | `handy --toggle-transcription` |
| `SUPER + C` / `SUPER + V` | Send `CTRL + INSERT` / `SHIFT + INSERT` to the active window |
| `SHIFT + ALT + left-button drag` | Move window |

### Rules and environment

The nine [window rules](../config/hypr/modules/windowrules.lua) preserve the captured matches and effects.
Tagged floating windows are centered at 1024x768.
The class list includes `blueberry.py`, `Impala`, `Wiremix`, `org.gnome.NautilusPreviewer`, `com.gabm.satty`, `TUI.float`, `imv`, and `mpv`.
Dialog tagging requires both the class match and title match.
Calculator floats, fullscreen windows lose their border, fullscreen inhibits idle, and all windows suppress maximize events.

The [environment module](../config/hypr/modules/env.lua) preserves all 16 entries, including `BROWSER=google-chrome-stable` and `QT_STYLE_OVERRIDE=kvantum`.
It keeps the Wayland backend preferences, Qt scaling and decoration settings, Hyprland desktop identifiers, and cursor sizes of 38.
XWayland uses zero scaling, and ecosystem update news is disabled.

### Companion tools and packages

| Tool | Preserved configuration |
| --- | --- |
| Hypridle | `lock_cmd = "hyprlock"`, lock at 900 seconds, suspend at 1800 seconds, and `ignore_dbus_inhibit = false` |
| Hyprlock | Clock/date, hidden cursor, no loading bar, Theme-colored password field, `$HOME/dotfiles/assets/wallpapers/dark-forrest-ultrawide.png`, and `$HOME/dotfiles/assets/face.jpg` |
| Hyprpaper | DP-1 wallpaper from `${home.homeDirectory}/dotfiles/assets/wallpapers/yellow-mountains.png` |
| Cursor | `capitaine-cursors`, size 38, GTK/X11/Hyprcursor installation enabled; compositor `enable_hyprcursor = false` keeps XCursor rendering |

The [package module](../modules/home-manager/hyprland/packages.nix) enables mpv and installs Ultrashell, pavucontrol, Nautilus, libnotify, wtype, and wl-clipboard.
It also installs Release Channel quickshell, hyprpaper, hyprshot, hyprpicker, and hyprcursor.
Hypridle and Hyprlock select their Release Channel packages in their own modules.
There is no `hyprdim`, `set-screen-share-resolution`, or `unset-screen-share-resolution` in the current module.

## Automated gates

[`checks/hyprland.nix`](../checks/hyprland.nix) registers seven focused checks under `checks.x86_64-linux`:

| Check | Coverage |
| --- | --- |
| `hyprland-lua-static` | StyLua, Luacheck, and Lua 5.5 syntax for native source and the test code |
| `hyprland-bridge-tests` | Decoder and bridge validation |
| `hyprland-semantic-fixture` | Strict comparison of supported records and deliberately invalid changes |
| `hyprland-parser-fixture` | Valid and invalid fixtures through the pinned parser |
| `hyprland-repo-ownership` | Actual module wiring, synthetic host data, companion/channel ownership, inert Darwin fixture, and exclusive Lua file ownership |
| `hyprland-production-parity` | Actual Home Manager entry and native modules against the captured baseline, including startup gating and the exact shutdown exception |
| `hyprland-production-parser` | Actual staged entry, modules, and bridge through Hyprland 0.55.4 `--verify-config` |

Run the repository gate from the repository root:

```sh
nix flake check
```

These checks do not activate the System.
Passing the seven focused checks is not a pass for the full flake gate.
[Run the automated Hyprland Lua quality gates](https://github.com/fveracoechea/dotfiles/issues/39) owns that result and code/test fixes.
The [verification contract](../checks/hyprland/README.md) distinguishes live option/binding/workspace evidence from disk-only environment, monitor-rule, window-rule, and lifecycle evidence.
Command recording does not prove process completion, lock/unlock, idle suspend, streaming, or session shutdown.

## User-only activation and recovery

Only the user runs the commands in this section on `nixos-desktop`.
Agents must not build or activate System configuration, run live state-changing tests, or perform rollback.
Wait for the automated gate, save work, and ensure a TTY login works before testing.
Use Bash for the command blocks and stop if a command fails.
Run repository-relative commands from the migration checkout's root.

### Save the exact pre-test system

Create a recovery directory once, before the first test.
Do not overwrite it during retries.
The GC root retains the already-built active System closure, including this flake's integrated Home Manager configuration.

```bash
state="$HOME/.local/state/hyprland-lua-migration"
test ! -e "$state" && mkdir -p "$state" &&
  nix-store --realise "$(readlink -f /run/current-system)" \
    --add-root "$state/pre-test-system" --indirect
test -x "$state/pre-test-system/bin/switch-to-configuration"
readlink -f "$state/pre-test-system"
readlink -f /nix/var/nix/profiles/system
hyprctl version -j > "$state/version-before.json"
hyprctl binds -j > "$state/binds-before.json"
hyprctl workspacerules -j > "$state/workspaces-before.json"
hyprctl monitors all -j > "$state/monitors-before.json"
```

Keep that directory through the test and any rollback.
It is local recovery data, not a replacement for the committed [hyprlang baseline](research/hyprland-live-baseline/README.md).

### Activate and start a fresh session

The user runs `nixos-rebuild test --flake .#nixos-desktop` with root permission:

```bash
sudo nixos-rebuild test --flake .#nixos-desktop
systemctl status home-manager-fveracoechea.service --no-pager
journalctl -b -u home-manager-fveracoechea.service --no-pager
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
test -f "$config_home/hypr/hyprland.lua"
test ! -e "$config_home/hypr/hyprland.conf"
test ! -L "$config_home/hypr/hyprland.conf"
readlink -f "$config_home/hypr/entry.lua"
jq . "$config_home/dotfiles/hyprland.json"
```

Confirm that `entry.lua` resolves into the Nix store and the bridge contains the host values above.
Do not delete an unexpected `hyprland.conf` or hand-edit a generated file to force the test through.
Resolve file ownership or activation errors first.
After saving work, log out through UWSM with `uwsm stop`, then select the UWSM-managed Hyprland session in Ly.
This fresh start is required to test Lua selection, environment, startup, and shutdown.
Do not substitute `hyprctl reload config-only` for it.

### Inspect the fresh Lua session

```bash
state="$HOME/.local/state/hyprland-lua-migration"
baseline="docs/research/hyprland-live-baseline/hyprctl"
set -o pipefail
hyprctl version -j
hyprctl configerrors -j | jq -e 'all(.[]; . == "")'
hyprctl binds -j > "$state/binds-after.json"
jq -e 'length == 46' "$state/binds-after.json"
hyprctl workspacerules -j > "$state/workspaces-after.json"
hyprctl monitors all -j > "$state/monitors-after.json"
while IFS= read -r option; do
  hyprctl getoption "$option" -j
done < <(jq -r '.[].option' "$baseline/options.json") |
  jq -s . > "$state/options-after.json"
diff -u <(jq -S 'sort_by(.option)' "$baseline/options.json") \
  <(jq -S 'sort_by(.option)' "$state/options-after.json")
diff -u <(jq -S . "$baseline/workspacerules.json") \
  <(jq -S . "$state/workspaces-after.json")
diff -u <(jq -S 'map(del(.dispatcher, .arg, .mouse))' "$baseline/binds.json") \
  <(jq -S 'map(del(.dispatcher, .arg, .mouse))' "$state/binds-after.json")
systemctl --user status hyprland-session.target hypridle.service hyprpaper.service --no-pager
systemctl --user list-units 'wayland-*' 'uwsm*' --no-pager
```

Expect version 0.55.4, no config errors, 46 bindings, five persistent workspaces, and matching values for all 23 captured options.
Hyprland 0.55.4 can report no errors as `[""]`.
Lua bindings report dispatcher `__lua` with registry references instead of legacy dispatcher/argument pairs.
The Lua mouse binding also reports `mouse = false`; test the actual drag below.
The last diff compares the remaining binding fields in order, but it cannot prove dispatcher behavior.
Keep the raw dumps and use the semantic gate plus live actions for that evidence.
Inspect monitors for DP-1 at the declared mode and HDMI-A-1 disabled, rather than expecting runtime focus, workspace, or VRR fields to match a snapshot byte for byte.

### Live smoke test

Record pass/fail and logs in [Validate the native Lua session on nixos-desktop](https://github.com/fveracoechea/dotfiles/issues/40).
An untested item remains untested, not passed.

1. Confirm one Ultrashell instance, its bar, the DP-1 wallpaper, border Theme, cursor size, and no error overlay after login.
2. Test focus, split, floating, all three fullscreen actions, resizing, grouping, pseudo, workspace moves, and `SHIFT + ALT + left-button drag` using the binding table.
3. Open Chrome, Ghostty, Fuzzel, and Handy; test copy/paste and representative floating dialogs, Calculator, and fullscreen idle inhibition.
4. Run `hyprlock`, inspect its background, face image, clock/date, and input field, then unlock successfully.
5. With no idle inhibitor, leave the session idle and confirm locking at 15 minutes and suspend at 30 minutes; wake and unlock.
6. In Hyprland, run `enable-stream-output`, inspect `hyprctl monitors all -j` for HDMI-A-1 at `3840x2160@120` and position `5120x0`, then run `disable-stream-output` and confirm it is disabled again.
7. Check `systemctl --user show sunshine.service nixos-fake-graphical-session.target -p Id -p ActiveState`; both should be inactive in the UWSM Hyprland session.
8. Log out through `uwsm stop`, select the Steam Session in Ly, and wait for Sunshine's configured 10-second startup delay.
Verify Steam Big Picture on the Dummy Plug and connect from Moonlight to test capture, input, and stream start/stop.
From a user terminal or TTY, inspect `systemctl --user status sunshine.service nixos-fake-graphical-session.target --no-pager` and `journalctl --user -b -u sunshine.service --no-pager`.
9. Exit the Steam Session through Steam's session exit, return to the UWSM Hyprland session, and confirm Sunshine is inactive, HDMI-A-1 is disabled, and Ultrashell and the session target start without duplicates or errors.
Inspect `journalctl --user -b --no-pager` for shutdown/startup failures.

The Sunshine scripts deliberately ignore `hyprctl` failure outside Hyprland.
Their exit status alone cannot prove the output changed; inspect the monitor state in step 6.
Do not start Sunshine manually in Hyprland to bypass the Steam Session ownership check.

### Restore the saved system

If activation or a live check fails, stop the test and retain the logs.
From a TTY as `fveracoechea`, restore the saved closure with root permission:

```bash
state="$HOME/.local/state/hyprland-lua-migration"
pretest="$(readlink -f "$state/pre-test-system")"
test -x "$pretest/bin/switch-to-configuration" &&
  sudo "$pretest/bin/switch-to-configuration" test
test "$(readlink -f /run/current-system)" = "$pretest"
systemctl status home-manager-fveracoechea.service --no-pager
journalctl -b -u home-manager-fveracoechea.service --no-pager
```

This activates the saved, already-built flake System configuration without selecting a different profile generation or changing the boot default.
Check that Home Manager restored the pre-test config files before starting a fresh Hyprland session from Ly.
For a pre-migration snapshot, expect `hyprland.conf` and no `hyprland.lua`; do not try to reverse the language change with a reload alone.
If Home Manager failed, resolve the logged error and rerun the saved activation before calling recovery complete.
Then confirm no config errors and the previous desktop behavior.

Do not assume `nixos-rebuild test --rollback` restores the pre-test state.
At the pinned nixpkgs revision, `test` activates a closure without calling `set_profile`; it need not create a System profile generation.
`--rollback` selects from the profile history, not a saved copy of `/run/current-system` before the test.
It can therefore select a different, older configuration.
A reboot returns to the boot default, which can also differ from the pre-test active System.
The source is [`services.py`, `_activate_system` and `_rollback_system`](https://github.com/NixOS/nixpkgs/blob/c25784012c9982bca5b3e0de87e90bbdac8927d3/pkgs/by-name/ni/nixos-rebuild-ng/src/nixos_rebuild/services.py) and the pinned [`nixos-rebuild` manual](https://github.com/NixOS/nixpkgs/blob/c25784012c9982bca5b3e0de87e90bbdac8927d3/pkgs/by-name/ni/nixos-rebuild-ng/nixos-rebuild.8.scd).

Keep the recovery root until the user accepts the migration or verifies recovery.
Only after all gates pass should the user choose to persist the tested checkout with `sudo nixos-rebuild switch --flake .#nixos-desktop`.

## Deferred behavior and historical records

The migration changes the configuration language, not the existing desktop policy.
These facts remain unchanged:

- Window-rule patterns such as `[F|f]`, `[C|c]`, and `[open|save]` retain their original regex behavior, not their likely intended alternatives.
- Hyprpaper still hardcodes DP-1 instead of deriving monitor ownership from the host option.
- Wallpaper and Hyprlock image paths still depend on `$HOME/dotfiles/assets`, unlike the store-backed native Lua files.
- The `SUPER + J` split/focus overlap remains in its captured order.
- The one approved lifecycle behavior change is the synchronous shutdown stop and conditional 0.1-second wait.

The [original audit](research/current-hyprland-configuration-audit.md) and early [verification](research/hyprland-lua-verification.md) and [bridge research](research/hyprland-lua-data-bridge.md) remain historical evidence.
Their out-of-store assumptions, generated-settings proposals, manual `config-only` reload steps, and `test --rollback` advice are not current operating instructions.
The [module seam decision](https://github.com/fveracoechea/dotfiles/issues/34) and its shutdown follow-up replace those proposals.
The channel decision in ADR-0007 still applies; its statement that the Lua port is future work describes the state before this migration.
Use this document and the source-linked verification contract for the implemented behavior.
