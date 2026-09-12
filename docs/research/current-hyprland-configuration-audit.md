# Audit: Current Hyprland Configuration (Pre-Lua Migration)

Audit date: 2026-09-12. Branch: `research/hyprland-current-config` (even with `main`).

Purpose: inventory every setting and generated artifact the Hyprland-to-Lua migration must preserve, map ownership boundaries, flag stale docs, interpolation and package-path hazards, host-specific monitor data, and the candidate seams between Nix and Lua. This document does not decide the migration design; it feeds the Wayfinder map.

## 1. Migration driver

ADR-0007 (docs/adr/0007-split-nixpkgs-channels-by-package-owner.md, consequence list, bullet 8) records the constraint:

- nixos-26.05 holds Hyprland **0.55.4**, the last version that reads `hyprland.conf` (hyprlang). 0.56 dropped hyprlang for `hyprland.lua`.
- The compositor is a Release Channel system package (no flake input, cache.nixos.org hits). The config must be ported to Lua before the release moves to 26.11.
- `wayland.windowManager.hyprland.configType` is set explicitly to `"hyprlang"` (modules/home-manager/hyprland/settings.nix:20) so the HM module default (which flips to `"lua"` at `home.stateVersion` 26.05) can never drift. The comment there also warns: **a stray `hyprland.lua` wins over `hyprland.conf`**, so during migration the two formats must never coexist.
- `home.stateVersion` is 24.05 (hosts/nixos-desktop/home.nix:78), so the HM default has not flipped yet; only the explicit setting pins it.

## 2. Ownership boundaries

Hyprland spans two eval contexts with two switches of the same name; both must be enabled on a host (ADR-0004 rejected bridging them). CONTEXT.md and README.md:113-121 document this.

| Concern | Owner | File |
|---|---|---|
| Compositor package, portal, xwayland, uwsm | System (Release Channel `pkgs`) | modules/nixos/hyprland.nix:16-22 |
| Bluetooth, 32-bit graphics, session vars (`NIXOS_OZONE_WL`, `WLR_NO_HARDWARE_CURSORS`) | System | modules/nixos/hyprland.nix:10-14, 24-27 |
| Enable option (System side) | System | modules/nixos/hyprland.nix:7 |
| All compositor config, env, bindings, windowrules, theme | Home (`wayland.windowManager.hyprland.settings`) | modules/home-manager/hyprland/*.nix |
| Enable option + `monitors` sub-option | Home | modules/home-manager/hyprland/default.nix:15-23 |
| Host monitor spec strings | Host declaration | hosts/nixos-desktop/home.nix:22-28 |
| Satellite packages (quickshell, hyprpaper, hyprshot, hyprpicker, hyprcursor, hypridle, hyprlock) | Home, but **Release Channel** as Version-Coupled Packages | modules/home-manager/hyprland/packages.nix:23-27, hypridle.nix:11, hyprlock.nix:23, hyprpaper.nix:14; ADR-0007 |
| Hyprland package in HM | Deliberately `null`/`null` so System owns it | modules/home-manager/hyprland/settings.nix:13-14 |
| Ultrashell wrapper | `dotfilesPkgs` (Latest Channel source, Release Channel Hyprland deps) | packages/default.nix:13; ADR-0007 |
| Ly display manager, uwsm session launch | System | modules/nixos/display-manager.nix; `withUWSM = true` in modules/nixos/hyprland.nix:18 |
| Steam Session (gamescope on HDMI-A-1) | System gaming module; Hyprland never activates `nixos-fake-graphical-session.target` | modules/nixos/gaming.nix:30-47, 98-112; ADR-0006 |
| Dummy Plug toggle scripts calling `hyprctl keyword monitor` | Home sunshine module | modules/home-manager/sunshine.nix:50-57 |

macOS (`hosts/macbook-pro/`) uses aerospace, not Hyprland; the HM hyprland module is shared but inert there (gated by `dotfiles.hyprland.enable`).

## 3. Inventory of settings to preserve

All Home-side settings go through `wayland.windowManager.hyprland` (HM module from the Latest Channel; home-manager follows `nixpkgs-latest`).

### 3.1 Core settings (modules/home-manager/hyprland/settings.nix)

| Setting | Value | Notes |
|---|---|---|
| `systemd.enable` | `true` | |
| `package` / `portalPackage` | `null` / `null` | System owns both |
| `configType` | `"hyprlang"` (explicit) | Flip target of the migration |
| `monitor` | `config.dotfiles.hyprland.monitors` (host list) | see section 5 |
| `cursor.enable_hyprcursor` | `false` | XCursor path in use; hyprcursor still enabled at pointer level (3.7) |
| `misc.vrr` | `2` | |
| `misc.animate_manual_resizes` | `true` | |
| `misc.animate_mouse_windowdragging` | `true` | |
| `exec-once` | `ultrashell` | status bar, by PATH name |
| `general.layout` | `"dwindle"` | |
| `general.border_size` | `3` | |
| `general.resize_on_border` | `true` | |
| `general.gaps_in` | `10` | |
| `general.gaps_out` | `"10,18,18,18"` | per-side string |
| `layout.single_window_aspect_ratio` | `"16 9"` | comment: avoids overly wide single windows |
| `dwindle.preserve_split` | `true` | |
| `dwindle.force_split` | `2` | |
| `decoration` | `mkForce { rounding = 8; blur.enabled = true; }` | **mkForce** wipes other decoration values; Lua side must reproduce the final value, not a merge |
| `master.allow_small_split` / `mfact` / `new_on_top` | `true` / `0.32` / `false` | master config present although dwindle is active |
| `binds.drag_threshold` / `allow_workspace_cycles` | `10` / `true` | |
| `workspace` | `map (i: "${toString i}, persistent:true") [1..5]` | Nix list comprehension generates 5 strings |

### 3.2 Bindings (modules/home-manager/hyprland/bindings.nix)

Local Nix helpers (`openapp`, `movefocus`, `resizeactive`) and a `map` over 1-9 generate the `bindd` list. Constants: `terminal = "ghostty"`, `browser = "google-chrome-stable"`, `search = "fuzzel --cache ${config.home.homeDirectory}/.config/fuzzel/cache"`, `handy = "handy --toggle-transcription"`.

- `bindm`: `SHIFT_ALT, mouse:272, movewindow` (resize binding commented out, line 11).
- `bindd` has 27 fixed entries: split toggle (`SUPER, J`), float toggle, fullscreen 0 / fullscreenstate 0 2 / fullscreen 1, killactive, four movefocus (K/J/L/H map to u/d/r/l), four resizeactive, pseudo + allpseudo via `hyprctl dispatch`, workspace cycle via TAB (e+1 / e-1 / previous), group toggle + moveoutofgroup, four app launchers (B browser, S terminal, A search, O handy), clipboard bridge via `sendshortcut` CTRL/SHIFT INSERT.
- Generated entries: `SUPER, 1-9` workspace switch; `SUPER SHIFT, 1-9` movetoworkspace.
- Attribution comment points at Omarchy's tiling-v2.conf.

### 3.3 Environment (modules/home-manager/hyprland/env.nix)

`env` has 16 entries: `BROWSER`, Wayland-forcing block (`GDK_BACKEND`, `QT_QPA_PLATFORM`, `QT_STYLE_OVERRIDE=kvantum`, `SDL_VIDEODRIVER`, `MOZ_ENABLE_WAYLAND`, `ELECTRON_OZONE_PLATFORM_HINT`, `OZONE_PLATFORM`, `XDG_SESSION_TYPE`), QT DPI block (`QT_AUTO_SCREEN_SCALE_FACTOR`, `QT_QPA_PLATFORMTHEME=qt6ct`, `QT_WAYLAND_DISABLE_WINDOWDECORATION`), desktop identification (`XDG_CURRENT_DESKTOP`, `XDG_SESSION_DESKTOP` = Hyprland), cursor sizes (`XCURSOR_SIZE=38`, `HYPRCURSOR_SIZE=38`).

Plus `ecosystem.no_update_news = true` and `xwayland.force_zero_scaling = true`.

Note: `QT_STYLE_OVERRIDE=kvantum` and `QT_QPA_PLATFORMTHEME=qt6ct` reference tooling not installed by this module; preserving them verbatim is the current behavior.

### 3.4 Window rules (modules/home-manager/hyprland/windowrules.nix)

Class/title regexes are built with `builtins.concatStringsSep "|"`, then injected into `match:class (...)` groups.

- Tag plumbing: `float on` / `center on` / `size 1024 768` for `match:tag floating-window`; two `tag +floating-window` rules (floating classes; titled classes gated by `match:title`); Calculator floats unconditionally.
- `border_size 0, match:fullscreen 1`, `idle_inhibit fullscreen, match:class .*`, `suppress_event maximize, match:class .*`.
- Quirk to carry or consciously fix: `"Open [F|f]older.*"` (windowrules.nix:21) is a character class containing a literal `|`, not alternation. Same for `[C|c]hoose` and `.*wants to [open|save].*`.

### 3.5 Theme (modules/home-manager/hyprland/theme.nix)

`toRgb` converts palette hex (`#RRGGBB`) to `rgb(rrggbb)`. `general.col.active_border = "${blue} ${flamingo} 90deg"`, `col.inactive_border = surface2`. Palette source: `config.dotfiles.palette` (modules/core/palette.nix, hardcoded Catppuccin Mocha; multi-theme deferred).

### 3.6 hypridle (modules/home-manager/hyprland/hypridle.nix)

`package = pkgs-stable.hypridle` (Version-Coupled). `general.ignore_dbus_inhibit = false`, `lock_cmd = "hyprlock"`. Listeners: 900 s -> `hyprlock`, 1800 s -> `systemctl suspend`.

### 3.7 hyprlock (modules/home-manager/hyprland/hyprlock.nix)

`package = pkgs-stable.hyprlock`. `general.disable_loading_bar`, `hide_cursor`. `background` and `input-field` are **`mkForce`** lists (overriding HM module defaults). Wallpaper path: `$HOME/dotfiles/assets/wallpapers/dark-forrest-ultrawide.png`; face image: `$HOME/dotfiles/assets/face.jpg` (see section 6). Two `label`s with `cmd[update:5000]` date commands. The input field uses six palette colors via the same `toRgb` helper. The image border uses lavender, the seventh color in the module. The placeholders use `$USER`, `$FAIL`, `$ATTEMPTS`, and icon glyphs in `placeholder_text`/`fail_text`.

### 3.8 hyprpaper (modules/home-manager/hyprland/hyprpaper.nix)

`package = pkgs-stable.hyprpaper`. **Monitor `"DP-1"` is hardcoded in the module**, not taken from `dotfiles.hyprland.monitors`. Wallpaper: `${config.home.homeDirectory}/dotfiles/assets/wallpapers/yellow-mountains.png`.

### 3.9 Cursor (modules/home-manager/hyprland/hyprcursor.nix)

`home.pointerCursor`: `capitaine-cursors` (pkgs), size 38, `gtk`, `x11`, and `hyprcursor` enable flags. Pairs with `cursor.enable_hyprcursor = false` in the compositor (3.1): hyprcursor infrastructure is installed but the compositor uses the XCursor path.

### 3.10 Packages (modules/home-manager/hyprland/packages.nix)

`programs.mpv.enable`. Home packages: `dotfilesPkgs.ultrashell`, `pavucontrol`, `nautilus`, `libnotify`, `wtype`, `wl-clipboard` (Latest Channel); `quickshell`, `hyprpaper`, `hyprshot`, `hyprpicker`, `hyprcursor` (Release Channel, Version-Coupled per ADR-0007).

### 3.11 Host monitor data (hosts/nixos-desktop/home.nix:22-28)

```
"DP-1, 5120x1440@119.98Hz, auto, auto, bitdepth, 8, cm, auto"
"HDMI-A-1, disable"
```

Two connector facts live outside the monitor list and are host-coupled to the same hardware:

- `HDMI-A-1` geometry `3840x2160@120, 5120x0, 1` in the Sunshine toggle scripts (modules/home-manager/sunshine.nix:52) and `HDMI-A-1, disable` (line 55).
- Gamescope Steam Session output `-O HDMI-A-1` (modules/nixos/gaming.nix:45).

### 3.12 Runtime artifacts the config feeds

- `ultrashell` on `exec-once`; built from the ultrashell flake input with Release Channel Hyprland dependencies (ADR-0007). [Map a rebuild-driven global Theme architecture](https://github.com/fveracoechea/dotfiles/issues/15) tracks its Theme boundaries, with [Research Ultrashell Theme input boundaries](https://github.com/fveracoechea/dotfiles/issues/19) complete.
- `enable-stream-output` / `disable-stream-output` scripts mutate Hyprland monitor state via `hyprctl keyword` at Steam Session entry/exit.
- Ly launches the uwsm-wrapped Hyprland session; ADR-0006 depends on Hyprland being uwsm-managed so Sunshine stays exclusive to the Steam Session.

## 4. Interpolation and package-path concerns

1. **PATH-name references, not store paths.** Bindings and `exec-once` name `ghostty`, `google-chrome-stable`, `fuzzel`, `handy`, `ultrashell`, `hyprctl`, `hyprlock`, `systemctl` bare. Resolution relies on the session PATH that HM/systemd build. A hand-written Lua file preserves this only if the launcher environment is unchanged; deriving store paths in Lua is impossible without Nix generating part of the file.
2. **`config.home.homeDirectory` interpolation** in the fuzzel cache flag (bindings.nix:21) and in hyprpaper/hyprlock wallpaper paths. In hand-written Lua this must either be hardcoded to `/home/fveracoechea`, sourced from `$HOME`, or generated.
3. **Wallpapers are repo-checkout paths, not Nix store paths.** `$HOME/dotfiles/assets/...` assumes the repo lives at `/home/fveracoechea/dotfiles` (this worktree confirms that layout). This is a live-edit affordance, not a reproducible store reference. Note the asymmetry: `.face` *is* copied into the store by HM (hosts/nixos-desktop/home.nix:34-35) while hyprlock's `image.path` is not.
4. **Nix-generated repetition.** Persistent workspaces (map over 1-5), 18 workspace bindings (two maps over 1-9), and the windowrule regexes are generated by Nix code. A Lua port either writes them out longhand or keeps a generator.
5. **Palette conversion.** `toRgb` (`lib.substring 1 6` + lowercase) appears in three modules (theme, hyprlock, and a `toHex` variant in fuzzel). In Lua the colors become literals; a later palette change would no longer propagate automatically. This intersects with [Map a rebuild-driven global Theme architecture](https://github.com/fveracoechea/dotfiles/issues/15): the palette is the planned Theme input.
6. **`mkForce` semantics.** `decoration` (settings.nix:58) and hyprlock's `background`/`input-field` rely on HM merge/override mechanics. Hand-written Lua has no merge: final values must be complete and single-sourced.
7. **configType flip hazard.** The HM default flips to `"lua"` at stateVersion 26.05. During migration the explicit `configType` must move in the same commit that introduces/removes the Lua file, because a stray `hyprland.lua` silently wins over `hyprland.conf` (settings.nix:16-20).

## 5. Host-specific monitor data

- The only monitor consumer of `dotfiles.hyprland.monitors` is `settings.monitor` (settings.nix:23). The option is typed `listOf str`, so spec strings are opaque; the Lua migration needs no parsing, only passthrough.
- `hyprpaper` hardcodes `DP-1` instead of reading the option; on a host with different connectors this module is already host-coupled. Flagged as a candidate seam: monitor identity could come from the host declaration when the config becomes Lua.
- `HDMI-A-1` appears in three places that must stay consistent: the disabled entry in the monitor list, the Sunshine toggle scripts, and the gamescope `-O` argument. The Lua migration must not break the Sunshine scripts (they call `hyprctl keyword`, which is format-stable) but should be listed in the parity check.
- `5120x1440@119.98Hz ... bitdepth, 8, cm, auto` encodes VRR-capable, 8-bit, cm (HDR color management) settings tied to the Samsung Odyssey ultrawide; `misc.vrr = 2` complements it.

## 6. Stale documentation found

| Doc | Stale content | Reality |
|---|---|---|
| docs/hyprland-summary.md:27 | `customUtils.monitors.samsung-odyssey` | `customUtils` deleted (CONTEXT.md); monitors come from `dotfiles.hyprland.monitors` |
| docs/hyprland-summary.md:48, 211, 220-222 | `hyprdim --fade 25`, `hyprdim` package, `set-screen-share-resolution` / `unset-screen-share-resolution` scripts | No `hyprdim` or helper scripts exist anywhere in the repo (`grep` confirms); `exec-once` runs only `ultrashell` |
| docs/hyprland-summary.md:32 | gaps out `10,20,20,20` | Actual: `10,18,18,18` (settings.nix:44) |
| docs/hyprland-summary.md (launchers table) | Missing `SUPER + O` handy binding; says `SUPER + A` is "Fuzzel application launcher" (it is, but via cache flag) | bindings.nix:62 |
| docs/hyprland-summary.md (packages table) | Lists only 7 packages; omits quickshell, pavucontrol, nautilus, libnotify, wtype, wl-clipboard | packages.nix |
| docs/hyprland-summary.md | No mention of uwsm, `configType`, Version-Coupled satellites, or the 0.55 hyprlang hold | ADR-0007 |
| docs/adr/0002:3 | "shared `customUtils.cattpuccin` attribute set" (customUtils) | Source of truth is now `config.dotfiles.palette` (ADR-0004, CONTEXT.md) |
| docs/adr/0004:21 | `config.dotfiles.monitors`; `dotfilesPkgs` wraps "hyprland, tmux-powerkit" | Option is `config.dotfiles.hyprland.monitors`; there is no hyprland flake input since ADR-0007; wrappers are herdr, tmux-powerkit, ultrashell (packages/default.nix) |
| README.md:121 | Monitor example shows only DP-1 | Host also disables HDMI-A-1 (hosts/nixos-desktop/home.nix:26) |

## 7. Seams between Nix and Lua (candidates, not decisions)

**Existing precedent for non-Nix config:** ADR-0005 puts hand-edited non-Nix config in a top-level `config/` directory, symlinked via `config.lib.file.mkOutOfStoreSymlink`. `config/nvim/` is the working example, with a check harness (checks/neovim.nix: stylua + luacheck + headless smoke test), lint script (scripts/check-lua.sh), and tooling configs (.luacheckrc, .stylua.toml, .luarc.json). A `config/hyprland/` port could reuse all of it.

**Seam 1: generation strategy.**
(a) Keep the HM settings attrsets and flip `configType` to `"lua"`, letting HM translate to `hyprland.lua`. Minimal diff, keeps Nix interpolation (monitors, home dir, palette) for free, but the config stays Nix-authored and the "native Lua tooling" motivation of ADR-0005 is not realized.
(b) Hand-write `config/hyprland/` Lua, symlink out-of-store. Native editing, but the dynamic pieces (monitor strings, palette colors, `$HOME` paths, PATH names) need either Nix-generated preamble files, environment access, or literals.
Hybrid shapes (Nix-generated values file + hand-written main file) sit between.

**Seam 2: what Nix must still inject.** At minimum: monitor strings (host option), palette colors (theme + hyprlock), `home.homeDirectory`-derived paths, and the `configType`/package wiring. Everything else is static and movable verbatim.

**Seam 3: satellite configs.** hypridle and hyprlock have their own HM-generated configs (separate formats, not affected by Hyprland's hyprlang->lua switch). Decide whether they ride along into the `config/` directory or stay HM-generated.

**Seam 4: validation.** `nix flake check` currently validates eval only; nothing parses the Hyprland config (AGENTS.md notes neovim lua is the checked Lua). A migration needs a parity gate: generated-vs-written diff against the current `hyprland.conf`, and/or a hyprlang/lua parse check modeled on checks/neovim.nix.

**Seam 5: runtime consumers.** Sunshine toggle scripts and ultrashell depend on Hyprland behavior (monitor state, IPC), not config format; they constrain testing (Steam Session + desktop session both need validation after the flip, per ADR-0007's release-validation list).

## 8. Parity checklist

Every box must be verifiable against the 0.55.4 `hyprland.conf` before the format flips.

- [ ] `monitor`: both host strings (DP-1 spec, HDMI-A-1 disable) render byte-identical
- [ ] `cursor.enable_hyprcursor = false`
- [ ] `misc`: vrr 2, animate_manual_resizes, animate_mouse_windowdragging
- [ ] `exec-once`: ultrashell only
- [ ] `general`: dwindle, border_size 3, resize_on_border, gaps_in 10, gaps_out 10,18,18,18, active/inactive border colors (blue/flamingo 90deg gradient, surface2)
- [ ] `layout.single_window_aspect_ratio = "16 9"`
- [ ] `dwindle`: preserve_split, force_split 2
- [ ] `decoration`: rounding 8, blur enabled (mkForce-equivalent final value)
- [ ] `master`: allow_small_split, mfact 0.32, new_on_top false
- [ ] `binds`: drag_threshold 10, allow_workspace_cycles
- [ ] `workspace`: 1-5 persistent
- [ ] `bindm`: SHIFT_ALT mouse:272 movewindow
- [ ] `bindd`: all 27 fixed bindings incl. fullscreenstate, sendshortcut clipboard bridge, hyprctl dispatch allpseudo; 18 mapped workspace bindings with descriptions
- [ ] `env`: all 16 entries verbatim
- [ ] `ecosystem.no_update_news`, `xwayland.force_zero_scaling`
- [ ] `windowrule`: all 9 rules, class/title regexes preserved (decide fate of the `[F|f]` quirk deliberately)
- [ ] hypridle: Release Channel package, lock_cmd, 900s/1800s listeners, ignore_dbus_inhibit
- [ ] hyprlock: Release Channel package, background (wallpaper path, blur), two date labels, face image with lavender border, input-field with all palette colors and placeholders (mkForce-equivalent)
- [ ] hyprpaper: Release Channel package, DP-1 preload/wallpaper, yellow-mountains path
- [ ] `home.pointerCursor`: capitaine-cursors, size 38, gtk/x11/hyprcursor flags
- [ ] Packages: mpv program; ultrashell, pavucontrol, nautilus, libnotify, wtype, wl-clipboard (Latest Channel); quickshell, hyprpaper, hyprshot, hyprpicker, hyprcursor (Release Channel)
- [ ] NixOS side untouched: programs.hyprland (uwsm, xwayland, package, portal), bluetooth, graphics, NIXOS_OZONE_WL, WLR_NO_HARDWARE_CURSORS
- [ ] Sunshine toggle scripts still toggle HDMI-A-1 correctly against the new config
- [ ] `configType` and the presence/absence of config files move in one commit; no `hyprland.lua` + `hyprland.conf` coexistence
- [ ] Channel rules intact: compositor stays System-owned on the Release Channel; satellites stay `pkgs-stable` with ADR-0007 reasons at each use site
- [ ] macbook-pro still evaluates (module shared, hyprland inert)
- [ ] Validation gate exists for the new format (flake check or script, modeled on checks/neovim.nix)
- [ ] docs/hyprland-summary.md rewritten or retired; ADR-0002/0004 stale references fixed

## 9. Planning decisions that remain

1. Generation strategy: HM-translated Lua vs hand-written `config/hyprland/` (Seam 1), and if hand-written, how Nix injects monitors, palette, and home paths.
2. Whether hypridle/hyprlock configs migrate to hand-written files or stay HM-generated (Seam 3).
3. Fate of the `[F|f]` windowrule regex quirk: preserve byte-identical behavior first, fix in a follow-up.
4. Whether hyprpaper's hardcoded `DP-1` should start reading `dotfiles.hyprland.monitors` (separate refactor, but cheap to fold in).
5. Shape of the parity/validation gate (diff against generated 0.55 config vs parse check vs both).
6. Whether the stale docs are fixed in this migration's scope or in the Theme map / doc-hygiene pass.
