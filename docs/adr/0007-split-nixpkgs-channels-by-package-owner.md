# Split nixpkgs channels by package owner

The servers temporarily retain their deployed dependency graph under [ADR-0008](0008-preserve-server-software-during-consolidation.md).
The channel policy below remains unchanged for the desktop.

This flake pulls from two nixpkgs channels.
Package ownership decides the channel by default.
The Release Channel builds packages owned by the System layer.
The Latest Channel, `nixpkgs-latest` on `nixpkgs-unstable`, builds packages owned by the Home layer.
This policy applies to Nix packages and Nix flake inputs.
Volta has a separate update policy.
Before this split, one `nixos-unstable` input fed everything, so a tool update also moved the kernel and could force a Hyprland source build.

Package ownership decides the channel, with two narrow departures:

- **Version-Coupled Package.** A package follows its partner's channel when compatibility depends on a shared protocol, ABI, IPC interface, patch process, or configuration format. The Hyprland satellites (`xdg-desktop-portal-hyprland`, `hyprpaper`, `hyprshot`, `hyprpicker`, `hyprcursor`, `hypridle`) therefore come from the Release Channel with the compositor. DankMaterialShell and Quickshell come from the Latest Channel because DMS depends on current Quickshell QML APIs and its upstream Home Manager module owns both packages. Compatibility takes priority over freshness, and each coupled set must be explicit.
- **Channel Hold.** A Home-owned package may temporarily come from the Release Channel when its Latest Channel package does not build or work. The use site records the failure and the condition for returning to the package owner's channel.

## Consequences

- Routine updates advance only `nixpkgs-latest`.
  Home Manager and app or tool inputs update separately when needed.
  Release updates move `nixpkgs-stable`.
  Updating Home apps and development tools must not move the kernel, services, login path, compositor, or other System components.
- The System Toolset contains only packages needed for boot, administration, recovery, or by a System Module. `vim`, `git`, and `curl` form the general recovery set; `ethtool` remains for network administration. Personal development tools and desktop utilities belong to Home Manager. Duplicate commands remain only when the System copy has a clear recovery purpose.
- System Modules keep integrated packages such as Docker and login shells on the Release Channel. Home Manager owns companion tools such as `lazydocker`, `docker-compose`, `pavucontrol`, `nautilus`, `wl-clipboard`, and `libnotify`, so they use the Latest Channel. Firefox remains on the Release Channel while the NixOS `programs.firefox` option owns it.
- Gaming packages take the Latest Channel even where a System Module installs them: Steam, protontricks, `proton-ge-bin`, gamescope (which also serves the Steam Session), `gamescope-wsi`, LACT, OpenRGB, and Sunshine are routed through their module package options. GameMode stays on the Release Channel because the 26.05 module exposes no package option.
- Hex is owned by Home Manager and uses `anomaly-hex` from the Latest Channel.
  Its flake input supplies only the Home Manager module.
  It uses desktop shortcuts and Wayland paste helpers, not privileged input-device access.
  The desktop keeps its existing input support for Sunshine.
- `nixpkgs.pkgs` receives an already-built instance, and NixOS asserts that `nixpkgs.config` is empty in that case. So `allowUnfree` and `permittedInsecurePackages` live in `nixpkgsConfig` in `flake.nix`, shared by both instances, and hosts can no longer declare them.
- Home Manager runs on the Latest Channel through a plain `_module.args.pkgs` definition, which replaces the `mkDefault` that `useGlobalPkgs = true` supplies.
  Its submodule receives the Latest Channel's `lib`, extended with Home Manager's functions.
  The outer System module tree, System Module definitions, and System packages remain on the Release Channel.
  `home.enableNixpkgsReleaseCheck` is off because the check reads the System package set and therefore reports the intentional channel split.
- The Release Channel tracks `nixos-YY.MM` in `nixpkgs-stable`.
- The Latest Channel tracks `nixpkgs-unstable`, not `nixos-unstable`.
  The NixOS VM tests gate `nixos-unstable`, but do not test the Home layer this input supplies.
  `nixos-unstable-small` runs a reduced test set and builds fewer packages, so cache coverage is thinner.
- Home Manager follows `nixpkgs-latest` but its source revision updates separately.
  App and tool inputs, including DMS and Operator, also follow `nixpkgs-latest` and update individually.
  musnix follows `nixpkgs-stable`.
  Hyprland comes from the Release Channel, not a separate compositor input.
  Its version follows the release, which can delay new features.
  The native Lua configuration and its explicit `configType` must match that version.
- Zsh is a Version-Coupled Package because the System registers it as the login shell.
  Home Manager and tmux use `pkgs-stable.zsh` so the configured shell and the executed shell match.
  Shell tools and plugins remain on the Latest Channel.
- Unused flake inputs are removed rather than kept current. `neovim-config` is removed because no host or module consumes it.
- Custom Packages and flake-input wrappers are built on the Latest Channel in `packages/default.nix`; consumers keep reading `dotfilesPkgs.<name>` and no call site knows the plumbing. System-only packages such as the compositor stay out of it and come straight from the System layer's Release Channel `pkgs`.
- Home modules receive `pkgs-stable` only for an explicit Version-Coupled Package or Channel Hold. Each use states its reason beside the assignment. Ordinary Home packages use the default Latest Channel `pkgs`; ordinary nixpkgs packages do not enter Dotfiles Pkgs.
- Latest Channel updates run `nix flake check` and the user-only `nixos-rebuild test --flake .#nixos-desktop`.
  A Release update runs the same checks, stages the NixOS generation with `nixos-rebuild boot`, reboots, and validates boot, login, Hyprland, networking, audio, and the Steam Session before merge.
  After each Latest update, DMS and Quickshell are tested together.
  Zettlr is also tested from the Latest Channel, and its hold remains until both its build and launch succeed.
