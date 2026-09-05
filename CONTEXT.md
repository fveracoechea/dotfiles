# Dotfiles Context

Personal NixOS/nix-darwin dotfiles repository using flakes. Manages reproducible, cross-platform development environments across multiple physical machines.

## Language

**Host**:
A physical machine managed by this repository. Each host has its own directory under `hosts/` containing system and user configuration.

**Custom Utils**:
_Appears in legacy code only._ Previously shared utilities injected into all modules via `specialArgs`, including the color palette and monitor specs. Replaced in the refactor by `config.dotfiles.palette` (a plain attrset option) and `config.dotfiles.hyprland.monitors` (a host-declared list under the hyprland sub-option). The `utils/` directory is deleted.
_Avoid_: utils, helpers, constants

**Custom Package**:
A package defined locally in this repository and built via `callPackage`, not available in nixpkgs.
_Avoid_: local package, in-repo package

**Custom Pkgs**:
_Appears in legacy code only._ Previously the set of custom packages built for the target system and injected into all modules via `specialArgs`. Replaced by `dotfilesPkgs`.

**Dotfiles Pkgs**:
The set of packages this flake provides to its modules via `specialArgs`, injected under the name `dotfilesPkgs`. Contains two kinds of packages: locally-built packages defined in `packages/` and packages wrapped from the flake's non-nixpkgs inputs (e.g. `tmux-powerkit`). All are built on the Latest Channel. Modules read `dotfilesPkgs.<name>` instead of touching `inputs` or `system` directly, so external consumers only need to pass `dotfilesPkgs` to use the flake.
_Avoid_: customPkgs, custom packages, local packages

**Release Channel**:
A platform-specific nixpkgs release branch that builds System-owned packages. It moves through deliberate Release updates, not routine app and tool updates. See ADR-0007.
_Avoid_: stable, stable channel, stable nixpkgs

**Latest Channel**:
The `nixpkgs-unstable` branch that builds Home-owned packages. It moves on demand without disturbing the Release Channel.
_Avoid_: unstable, unstable channel, bleeding edge

**Version-Coupled Package**:
A package whose working version is tied to a package on the other side of the channel seam, so it takes its partner's channel instead of its owner's channel. See ADR-0007.
_Avoid_: pinned package, exception, override

**Packaging Exception**:
A package that takes the channel for its purpose instead of its System location because only a packaging constraint prevents Home Manager from owning it. Use only when separating the package from its System integration is not practical. See ADR-0007.
_Avoid_: app override, layer exception

**Channel Hold**:
A temporary assignment to the other channel because a package does not build or work from its default channel. A Channel Hold needs a reason and an exit condition. See ADR-0007.
_Avoid_: pin, workaround, exception

**System Toolset**:
The small set of Release Channel packages needed for boot, administration, recovery, or by a System Module. Personal development tools and desktop utilities belong to the Home layer instead.
_Avoid_: system packages, global tools

**Theme**:
A visual style applied consistently across applications. Themes are configured per-application in each module rather than via a unified theming framework like Stylix.
_Avoid_: color scheme, palette, style

**State Version**:
A compatibility marker (`system.stateVersion` or `home.stateVersion`) that preserves migration behavior across Nix/Home Manager upgrades.
_Avoid_: version, state

**System**:
OS-level configuration for a host. On NixOS this includes bootloader, networking, services, and hardware. On macOS this includes nix-darwin system defaults and Homebrew.

**Home**:
User-level configuration for a host, managed by Home Manager. Includes dotfiles, shell configuration, applications, and themes.

**Home Manager Module**:
A module under `modules/home-manager/` that configures a user-level concern. These modules are shared across all platforms (NixOS and macOS) and imported into each host's `home.nix`.

**System Module**:
A module under `modules/nixos/` or `modules/darwin/` that configures an OS-level concern specific to one platform. NixOS modules configure bootloader, services, networking, and hardware. Darwin modules configure macOS system defaults, Homebrew, and shell integration.

**Dotfiles Option**:
A boolean enable switch under the `dotfiles.*` namespace that activates a personal configuration for an app, service, or grouping of them. Hosts activate modules by setting `dotfiles.<name>.enable = true`. An option may cover a single app (e.g. `dotfiles.ghostty`) or a grouping of several apps under one concern (e.g. `dotfiles.shell` = zsh + tmux + oh-my-posh + bat + btop + yazi + git). Groupings cascade to their members via `mkDefault`, so a host can opt out of any member by setting it to `false` explicitly. Groupings are distinguished from atomics by name only, not by a marker. Some modules expose sub-options under their namespace (e.g. `dotfiles.hyprland.monitors`).
_Avoid_: bundle, configuration, profile

**Grouping**:
A `dotfiles.*` module that composes several atomic `dotfiles.*` modules under one enable switch. The grouping imports its members (so their options exist) and sets each member's `enable` to `mkDefault true` under its own `mkIf`. A host enables the grouping for the full set, or overrides individual members to `false` to opt out. Examples: `dotfiles.shell`, `dotfiles.gaming`.
_Avoid_: bundle, profile, suite

**Config Directory**:
A top-level `config/` directory at the repo root that holds non-Nix application configuration files (lua, json, toml), namespaced per application (e.g. `config/nvim/`). Each Home Manager module symlinks its application's subdirectory into place via `config.lib.file.mkOutOfStoreSymlink`, so the files are edited in their native format with full editor tooling rather than embedded as Nix string literals. See ADR-0005.
_Avoid_: config folder, dotfiles directory

**Steam Session**:
The gamescope session launched from the display manager on `nixos-desktop` that runs Steam Big Picture fullscreen on the Dummy Plug. This is the only session Sunshine serves.
_Avoid_: gamescope session, big picture session

**Dummy Plug**:
A headless HDMI display emulator plugged into the GPU on `nixos-desktop` (connector `HDMI-A-1`). It presents a 4K120 HDR-capable EDID so the GPU renders a streamable output with no physical display attached.
_Avoid_: virtual display, fake monitor, headless dongle
