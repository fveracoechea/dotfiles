# Hyprland Configuration Summary

This document summarizes the Hyprland window manager configuration defined in `modules/home-manager/hyprland/`.

## Files

| File | Purpose |
|------|---------|
| `default.nix` | Imports all Hyprland-related modules |
| `settings.nix` | Core Hyprland settings (layout, monitor, decorations) |
| `bindings.nix` | Keybindings and mouse bindings |
| `env.nix` | Environment variables and XWayland settings |
| `packages.nix` | Hyprland-related packages and helper scripts |
| `windowrules.nix` | Window rules for floating, borders, idle inhibition |
| `theme.nix` | Catppuccin Mocha color theme for borders |
| `hypridle.nix` | Idle / lock / suspend management |
| `hyprlock.nix` | Lock screen appearance |
| `hyprpaper.nix` | Wallpaper configuration |
| `hyprcursor.nix` | Cursor theme configuration |

---

## Core Settings

**Layout:** Dwindle layout with `preserve_split` and `force_split = 2`.

**Monitor:** Uses `customUtils.monitors.samsung-odyssey`.

**General:**

- Border size: `3`
- Gaps: `10` inner; `10,20,20,20` outer
- Rounding: `8`
- `resize_on_border = true`
- `single_window_aspect_ratio = "16 9"`
- Master layout `mfact = 0.32`

**Decorations:**

- Rounding: `8`
- Blur: enabled
- VRR: `2`
- Animations enabled for manual resizes and mouse dragging

**Startup:**

- `ultrashell` (status bar)
- `hyprdim --fade 25`

**Persistent workspaces:** 1–5

---

## Keybindings

Modifier key: `SUPER`

### Window / Tiling Control

| Key | Action |
|-----|--------|
| `SUPER + J` | Toggle split |
| `SUPER + T` | Toggle floating / tiling |
| `SUPER + F` | Fullscreen |
| `SUPER + CTRL + F` | Tiled fullscreen |
| `SUPER + ALT + F` | Full width |
| `SUPER + W` | Close active window |
| `SUPER + K/J/L/H` | Move focus up/down/right/left |
| `SUPER + CTRL + K/J/L/H` | Resize active window |
| `SUPER + P` | Pseudo tile |
| `SUPER + CTRL + P` | Toggle all pseudo |
| `SUPER + G` | Toggle grouping |
| `SUPER + ALT + G` | Move active window out of group |

### Workspaces

| Key | Action |
|-----|--------|
| `SUPER + 1-9` | Switch to workspace 1-9 |
| `SUPER + SHIFT + 1-9` | Move window to workspace 1-9 |
| `SUPER + TAB` | Next workspace |
| `SUPER + SHIFT + TAB` | Previous workspace |
| `SUPER + CTRL + TAB` | Former workspace |

### Application Launchers

| Key | Action |
|-----|--------|
| `SUPER + B` | Google Chrome |
| `SUPER + S` | Ghostty terminal |
| `SUPER + A` | Fuzzel application launcher |

### Mouse

| Binding | Action |
|---------|--------|
| `SHIFT + ALT + LMB drag` | Move window |

---

## Window Rules

Floating windows are auto-detected by class or title and get:

- Floating enabled
- Centered
- Size `1024x768`

**Floating classes include:** `blueberry.py`, `Impala`, `Wiremix`, `org.gnome.NautilusPreviewer`, `com.gabm.satty`, `TUI.float`, `imv`, `mpv`.

**Floating title patterns include:** file open/save dialogs, choose dialogs, `xdg-desktop-portal-gtk`, `DesktopEditors`, `org.gnome.Nautilus`.

Other rules:

- `org.gnome.Calculator` floats
- Border size `0` for fullscreen windows
- Idle inhibit during fullscreen
- Suppress maximize events

---

## Environment Variables

Forces Wayland wherever possible:

```
GDK_BACKEND=wayland,x11,*
QT_QPA_PLATFORM=wayland;xcb
SDL_VIDEODRIVER=wayland
MOZ_ENABLE_WAYLAND=1
ELECTRON_OZONE_PLATFORM_HINT=wayland
OZONE_PLATFORM=wayland
XDG_SESSION_TYPE=wayland
XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_DESKTOP=Hyprland
```

**QT / DPI:**

- `QT_AUTO_SCREEN_SCALE_FACTOR=1`
- `QT_QPA_PLATFORMTHEME=qt6ct`
- `QT_WAYLAND_DISABLE_WINDOWDECORATION=1`

**Cursor:**

- `XCURSOR_SIZE=38`
- `HYPRCURSOR_SIZE=38`

**XWayland:** `force_zero_scaling = true`.

---

## Theme

Uses **Catppuccin Mocha** colors:

- Active border: blue → flamingo gradient at 90°
- Inactive border: surface2

The `theme.nix` converts hex colors to `rgb(...)` strings using a small helper.

---

## Hyprlock

- Enabled
- Wallpaper: `assets/wallpapers/dark-forrest-ultrawide.png`
- Profile image: `assets/face.jpg`
- Shows clock and date labels
- Password field with Catppuccin-themed colors
- `disable_loading_bar = true`

---

## Hyprpaper

- Enabled
- Monitor: `DP-1`
- Wallpaper: `assets/wallpapers/yellow-mountains.png`

---

## Hypridle

| Timeout | Action |
|---------|--------|
| 15 min | Lock screen (`hyprlock`) |
| 30 min | Suspend (`systemctl suspend`) |

`ignore_dbus_inhibit = false`.

---

## Cursor

- Theme: `capitaine-cursors`
- Size: `38`
- Enables GTK, X11, and Hyprcursor support
- `enable_hyprcursor = false` in Hyprland settings (uses XCursor)

---

## Packages

Installed alongside Hyprland:

| Package | Description |
|---------|-------------|
| `mpv` | Media player |
| `ultrashell` | Status bar |
| `hyprdim` | Dim inactive windows |
| `hyprpaper` | Wallpaper utility |
| `hyprshot` | Screenshot utility |
| `hyprpicker` | Color picker |
| `hyprcursor` | Cursor theme utility |

### Helper scripts

| Script | Action |
|--------|--------|
| `set-screen-share-resolution` | Switches monitor to `samsung-odyssey-qhd` resolution |
| `unset-screen-share-resolution` | Restores `samsung-odyssey` resolution |

---

## Notes

- The Hyprland package itself is managed by the NixOS module; Home Manager sets `package = null` and `portalPackage = null`.
- Configuration targets a single-monitor, keyboard-driven workflow with tiling and minimal mouse use.
