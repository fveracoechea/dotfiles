# Hyprland Lua migration

The compositor uses the Hyprland 0.55.4 Lua configuration interface.
The four sources in [`config/hypr/`](../config/hypr/) are `entry.lua`, `settings.lua`, `windowrule.lua`, and `bindings.lua`.
Home Manager puts the content of `entry.lua` into its generated `hyprland.lua`.
It installs the other three Lua files beside it, for four installed files in total.
The System module owns the compositor and portal; Home Manager sets their package options to `null`.

`settings.lua` declares this desktop's DP-1 and disabled HDMI-A-1 outputs, layout, workspaces, environment, and border colors.
DP-1 requests 10-bit color and the monitor's preferred mode.
The preferred mode can change when the Samsung Odyssey G95SC switches between one input and 50:50 Multi View.
The border colors come from the packaged [Catppuccin Hyprland Mocha Lua theme](https://github.com/catppuccin/hyprland).
Home Manager substitutes its store path into `settings.lua` during installation.
This does not install a fifth file under `hypr/` or require a JSON bridge.
To change monitors, edit `config/hypr/settings.lua` and rebuild.
`windowrule.lua` declares window behavior and `bindings.lua` declares the keyboard and mouse shortcuts.
The launcher and clipboard bindings call DankMaterialShell.

Home Manager also owns Hypridle, Hyprpaper, cursor settings, and DankMaterialShell.
UWSM controls the graphical session target; Home Manager does not stop or start it from Hyprland's Lua config.
When Hyprland starts, `entry.lua` calls `uwsm finalize` so UWSM gets its Wayland display and instance signature.
DMS runs as a user service and owns the bar, launcher, clipboard history, and lock screen.
The service starts only after the UWSM Hyprland session target is active.
The DMS package has a small QML patch that limits the bar to 1896 pixels instead of applying fixed side padding.
The bar keeps that width at 5120 and 2560 pixels and fills narrower displays.
Hypridle asks DMS to lock after 15 minutes and suspends after 30 minutes.
Neither Ultrashell nor Hyprlock is part of this configuration.

The Lua sources are store-backed, so changes need a rebuild and Home Manager activation.
An internal stamp reloads running Hyprland instances after a Lua source change.
The first change from `hyprland.conf` to `hyprland.lua` requires a fresh session.
A reload of an old session does not prove that it selected the Lua config.

## Automated check

Run `nix flake check` from the repository root.
The `hyprland-config` check stages the Home Manager config and runs its generated `hyprland.lua` through the pinned Hyprland parser.
It also checks that `hyprland.conf` is absent.
The parser check does not prove that shortcuts, idle locking, DMS, or Steam Session behavior work in a desktop session.

## User-only activation and recovery

Only the user runs the System test and live session checks on `nixos-desktop`.
Save work and confirm a TTY login works before starting.
Run the commands from the migration checkout.

### Save the active system

Create the recovery root once, before the first test, and keep it through all retries.
It retains the exact active System closure, including its Home Manager configuration.

```bash
state="$HOME/.local/state/hyprland-lua-migration"
test ! -e "$state" && mkdir -p "$state" &&
  nix-store --realise "$(readlink -f /run/current-system)" \
    --add-root "$state/pre-test-system" --indirect
test -x "$state/pre-test-system/bin/switch-to-configuration"
readlink -f "$state/pre-test-system"
hyprctl binds -j > "$state/binds-before.json"
hyprctl monitors all -j > "$state/monitors-before.json"
```

### Activate and start a fresh session

```bash
sudo nixos-rebuild test --flake .#nixos-desktop
systemctl status home-manager-fveracoechea.service --no-pager
journalctl -b -u home-manager-fveracoechea.service --no-pager
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
test -f "$config_home/hypr/hyprland.lua"
test ! -e "$config_home/hypr/hyprland.conf"
readlink -f "$config_home/hypr/settings.lua"
```

Check that `settings.lua` resolves into the Nix store.
Do not edit generated config files or delete an unexpected `hyprland.conf` by hand.
Resolve activation errors first.
Then save work, run `uwsm stop`, and select the UWSM-managed Hyprland session in Ly.

### Inspect and exercise the session

```bash
state="$HOME/.local/state/hyprland-lua-migration"
hyprctl version -j
hyprctl configerrors -j | jq -e 'all(.[]; . == "")'
hyprctl binds -j > "$state/binds-after.json"
hyprctl monitors all -j > "$state/monitors-after.json"
hyprctl workspacerules -j
systemctl --user status wayland-session@hyprland.desktop.target hypridle.service hyprpaper.service dms.service --no-pager
```

Confirm version 0.55.4, no config errors, five persistent workspaces, DP-1 at its preferred mode, and HDMI-A-1 disabled.
For a single input, expect the G95SC's full 5120x1440 resolution.
Check `currentFormat` in `hyprctl monitors all -j`; a 10-bit format has `2101010` in its name, unlike the old `XRGB8888` format.
The parser check cannot prove that the DisplayPort link negotiates 10-bit output.
Hyprland notes that some screen-capture applications do not support 10-bit output.
Check the Catppuccin borders, wallpaper, cursor, and DMS bar.
Test focus, split, floating, fullscreen, resizing, groups, pseudo, workspace moves, and `SHIFT + ALT + left-button drag`.
Open Chrome, Ghostty, the DMS launcher with `SUPER + A`, and Handy.
Open clipboard history with `SUPER + V` and paste with `SUPER + SHIFT + V`.
Test representative floating dialogs and fullscreen idle inhibition.
Run `dms ipc call lock lock`, inspect the DMS lock screen, and unlock.
Without an idle inhibitor, verify lock at 15 minutes and suspend at 30 minutes.

Run `enable-stream-output` in Hyprland and inspect `hyprctl monitors all -j` for HDMI-A-1 at 3840x2160@120 and position 5120x0.
Run `disable-stream-output` and confirm it is disabled again.
Confirm Sunshine and both Steam Session targets are inactive in Hyprland:

```bash
systemctl --user show sunshine.service nixos-fake-graphical-session.target wayland-session@steam-gamescope-uwsm.target -p Id -p ActiveState
```

Log out through `uwsm stop` and select `Steam (UWSM)` in Ly.
The plain `Steam` entry remains available during migration.
Wait for Sunshine's configured startup delay.
In the Steam Session, check `systemctl --user is-active wayland-session@steam-gamescope-uwsm.target sunshine.service` from a TTY or remote shell.
Verify Steam Big Picture on the Dummy Plug and connect through Moonlight to test capture and input.
Inspect the Sunshine service and logs from a user terminal or TTY.
Run `uwsm stop` from a TTY or remote shell to exit the UWSM Steam Session, then return to `Hyprland (uwsm-managed)` in Ly.
Confirm Sunshine is inactive, HDMI-A-1 is disabled, and DMS is running.
Record pass or failure and the logs in [issue #40](https://github.com/fveracoechea/dotfiles/issues/40).

### Two-input Multi View

The [G95SC specifications](https://www.samsung.com/ca/monitors/gaming/odyssey-oled-g9-g95sc-49-inch-240hz-curved-dual-qhd-ls49cg954snxza/) list Multi View and separate DisplayPort and HDMI inputs.
Connect the NixOS desktop to DisplayPort and the MacBook to HDMI.
Use the MacBook's HDMI output or a USB-C to HDMI video adapter if the MacBook has no HDMI port.
The G95SC's USB-C hub ports do not carry a video signal, as [Samsung's connection guide](https://www.samsung.com/ae/support/displays/screen-issues-when-connecting-a-samsung-2023-oled-monitor-to-a-pc/) states.
On the monitor, select Multi View and create a 50:50 layout with DisplayPort and HDMI as the two sources.
This selection is in the monitor's interface; Hyprland cannot turn Multi View on.
Set the MacBook's external display to 2560x1440 in macOS Displays settings if it does not select the half-screen mode automatically.
Check the NixOS half with:

```bash
hyprctl monitors all -j | jq '.[] | select(.name == "DP-1") | {width, height, refreshRate, currentFormat, availableModes}'
```

Expect 2560x1440 on the NixOS side and verify the MacBook fills the other half without stretching.
The monitor may offer a different refresh rate, color depth, or HDR behavior in Multi View.
Hyprland's [monitor guide](https://wiki.hypr.land/Configuring/Basics/Monitors/) documents `preferred` and `bitdepth = 10`.
Check `currentFormat` again in this mode rather than assuming it remains 10-bit.
Return to single-input mode and confirm that NixOS regains 5120x1440 without editing Lua or rebuilding.
If either mode is blank, keep the monitor in the working mode and record its `availableModes` and `configerrors` in issue #40 before choosing a fixed mode or lower bit depth.

### Restore the saved system

If activation or a live check fails, stop and retain the logs.
From a TTY, restore the saved closure with root permission:

```bash
state="$HOME/.local/state/hyprland-lua-migration"
pretest="$(readlink -f "$state/pre-test-system")"
test -x "$pretest/bin/switch-to-configuration" &&
  sudo "$pretest/bin/switch-to-configuration" test
test "$(readlink -f /run/current-system)" = "$pretest"
systemctl status home-manager-fveracoechea.service --no-pager
journalctl -b -u home-manager-fveracoechea.service --no-pager
```

Check that Home Manager restored the pre-test config files before starting a fresh Hyprland session from Ly.
Do not assume `nixos-rebuild test --rollback` returns to the saved active System.
It selects a profile generation, which can differ from the configuration active before `test`.
Keep the recovery root until the migration passes or recovery is verified.
Only after all gates pass should the user persist the tested checkout with `sudo nixos-rebuild switch --flake .#nixos-desktop`.
