# Linux development environment

A Linux dotfiles configuration managed through Nix flakes and Home Manager.

## Main features

- **Keyboard Focused**: Efficient tiling window management with Hyprland
- **Minimal Distractions**: Clean, focused interface design
- **Configuration as Code**: Everything managed through Nix flakes
- **Modular Configuration**: Enable apps and services via `dotfiles.<name>.enable` switches under a unified namespace
- **Highly Customizable**: Groupings (`dotfiles.shell`, `dotfiles.gaming`) compose atomic modules with `mkDefault` opt-out
- **Reproducible**: Identical environments across multiple machines
- **Reusable**: Flake exports `homeManagerModules`, `nixosModules`, and `dotfilesPkgs` for external Linux consumers

## Supported systems

- **NixOS Desktop** (`nixos-desktop`): x86_64-linux gaming/development setup
- **Homelab** (`homelab`): application services, LAN DNS, home automation, GPU inference, and subnet routing
- **VPS** (`vps`): Headscale, Headplane, Caddy, Tailscale, and Fail2ban

This repository is the canonical configuration source for all three hosts.
See [server consolidation and deployment](docs/server-consolidation.md) before any server activation.

## Project commands

Run `just` to list the available recipes.
Deployment recipes evaluate all hosts, then activate without a confirmation prompt.
Complete the backup and recovery checks before deploying servers.

```sh
just evaluate                    # Evaluation only, no System builds or activation
just check                       # Build and run the flake checks
just manifests                   # Print evaluated host manifests
just check-lua                    # Run Neovim flake checks
just check-neovim-runtime         # Test first launch with plugin downloads
just hyprland-baseline test       # Run the baseline script's self-tests
just deploy-desktop
just deploy-homelab
just deploy-vps
```

Use `just deploy-vps hostinger` until the desktop's `vps` SSH alias is activated.
Use `just --dry-run deploy-vps` to inspect commands without running them.
`just test-desktop` activates temporarily; it is not a read-only check.

## Core tooling

### System and package management

- **[Nix Flakes](https://nixos.org/)**: Reproducible package management and system configuration
- **[Home Manager](https://github.com/nix-community/home-manager)**: User environment management

### Package channels

The desktop uses two nixpkgs channels, so Home packages can move without disturbing its System.
See [ADR-0007](docs/adr/0007-split-nixpkgs-channels-by-package-owner.md).
The servers temporarily retain a separate immutable dependency graph under [ADR-0008](docs/adr/0008-preserve-server-software-during-consolidation.md).

| Channel             | Input                       | Branch                   | Builds                        |
| ------------------- | --------------------------- | ------------------------ | ----------------------------- |
| **Latest Channel**  | `nixpkgs-latest`            | `nixpkgs-unstable`       | Home-owned packages           |
| **Release Channel** | `nixpkgs-stable`     | `nixos-26.05`            | Desktop System-owned packages |
| Server source | `nixpkgs-servers` | Immutable deployed revision | Both server Systems and homelab Home |

Package ownership decides the channel.
Version-Coupled Packages follow their partner.
A broken Latest package can use a documented Channel Hold.

```bash
# Newer coding agents, CLI, and apps. Leaves the kernel and compositor alone.
nix flake update nixpkgs-latest

# Move the System. Do this deliberately and test the desktop.
nix flake update nixpkgs-stable

# One tool only, when it has its own input.
nix flake update herdr
```

When a release lands, change `nixpkgs-stable` to `nixos-YY.MM` before updating that input.
Do not move `nixpkgs-servers` or the `server-*` compatibility inputs during personal-tool updates.
The server Release Channel migration requires separate review and data-recovery checks.

### Window management and desktop

- **[Hyprland](https://hyprland.org/)**: Dynamic tiling Wayland compositor
- **[DankMaterialShell](https://danklinux.com/)**: Desktop shell, launcher, notifications, clipboard, and lock screen
- **[Ly](https://github.com/fairyglade/ly)**: Display manager for UWSM-managed Hyprland and Steam sessions on NixOS
- **[Ghostty](https://mitchellh.com/ghostty)**: Fast, GPU-accelerated terminal emulator

### Development environment

The shell Grouping lives in `modules/shell/home.nix`; its System entry is `modules/shell/nixos.nix`.
The existing `dotfiles.shell.enable` and `dotfiles.system-shell.enable` switches remain separate across Home and System.
Zsh, tmux, Bat, Btop, Yazi, and Git keep their independent flat switches and Grouping opt-outs.
Optional aliases, the Git editor, and Yazi's Eza preview follow enabled companions without enabling them.
Home Zsh and tmux retain the System-compatible Zsh package.
Homelab still uses its frozen compatibility shell implementation and package graph.

`modules/networking/nixos.nix` owns reusable network policy; the Host owns its hostname and interface selection.

- **[Neovim](https://neovim.io/)**: Extensible text editor with custom configuration
- **[TMUX](https://github.com/tmux/tmux)**: Terminal multiplexer with custom scripts
- **[Zsh](https://zsh.sourceforge.io/)** + **[Oh My Posh](https://ohmyposh.dev/)**: Enhanced shell experience
- **[LazyGit](https://github.com/jesseduffield/lazygit)**: Terminal UI for Git operations
- **[Yazi](https://yazi-rs.github.io/)**: Blazing fast terminal file manager

### Neovim plugins and tools

The configuration and editor checks live in [fveracoechea/neovim](https://github.com/fveracoechea/neovim).
Linux and macOS consume the same Lua files and `vim.pack` plugin lockfile.
This flake pins the shared repository and follows the Latest Channel for its editor dependencies.
`dotfiles.neovim.enable` enables the shared Home Manager module.
The first launch downloads plugins and compiles parsers.

Update plugins in the shared repository, commit its lockfile, then run `nix flake update neovim` here.
Home Manager installs store-backed Lua files and a writable lockfile copy.
Activation advances an unchanged lockfile with the configuration revision and refuses local lockfile edits.
For development only, set `programs.neovim-config.pluginLockPath` to the shared checkout's lockfile at the same revision as the Lua configuration.
Sessions and undo files live in Neovim's state directory.

Run `bash scripts/check-neovim-runtime.sh` for an isolated first-launch test with real plugin downloads and parser compilation.
It builds only the editor package, not the System.
The sandboxed flake smoke check uses the shared module's generated Home Manager files and offline parser fixtures.

### Coding agents

OpenCode comes from the Latest Channel's nixpkgs package, with Home Manager schema validation enabled.
Operator comes directly from its upstream flake, pinned to release `v2.2.2`.
Operator owns global agent instructions, its full skill catalog, and its OpenCode server plugin.
Herdr and Hunk remain separately managed.
The desktop declares `nix-mcp` globally with an absolute Nix executable path.

After you rebuild, follow [Operator's update procedure](https://github.com/fveracoechea/operator/blob/v2.2.2/docs/update.md).
Finish active Operator assignments before any command can migrate device state.
Register this checkout only if it is not already registered, then inspect and select the OpenCode host through Operator's config plan/apply commands.
Do not replace existing device settings or credentials.

```sh
operator project register --json
operator config show --json
operator install --opencode --json
operator herdr install --json
operator ready --json
```

The installer checks Nix-owned links and installs all supported third-party skills globally.
These include Matt Pocock's productivity and engineering catalogs, `unslop`, and `show-me`.
Their current upstream commits are outside `flake.lock`, and the installer can replace edits to those skills.
Start a new agent session after the install so it loads the new instructions and skills.
From another project, run `opencode mcp list` to check that global `nix-mcp` connects.

### Voice dictation

Hex replaces Handy and uses the Latest Channel's `anomaly-hex` package.
Nix downloads a prebuilt package when the selected revision is in the binary cache.
The Hex flake input supplies only its Home Manager module, not the application package.
Its Home Manager user service starts with the Hyprland session and stops at logout.
It needs a working audio session and Vulkan driver.
Download a speech model after activation with `hex model install`, then open `hex` to select your microphone and settings.
Existing Handy settings and models stay on disk, but this configuration no longer modifies them.

Hold left `Alt` to dictate, then release it to stop and transcribe.
Recording starts after the keyboard repeat delay, so a short Alt tap does not start dictation.
Hyprland consumes the Alt key events to prevent application menus from taking focus.
Other Alt combinations held for a long time can also start dictation.
Use `Super+O` to toggle dictation.
These bindings call Hex directly and do not depend on its portal shortcut names.
Hex needs no privileged input-device access.
Existing input access remains for Sunshine.
See the [Hex Nix guide](https://github.com/anomalyco/hex/blob/dev/docs/nix.md) for service diagnostics and model setup.

### Other tools

- **[Volta](https://volta.sh/)**: JavaScript toolchain manager
- **[Bat](https://github.com/sharkdp/bat)**: Enhanced `cat` with syntax highlighting

## Theming

- **[Catppuccin Mocha](https://catppuccin.com/)**: Consistent pastel theme across all applications, sourced from a single palette via `config.dotfiles.palette`
- **Custom wallpapers**: Curated collection in `assets/`

## Module system

Reusable modules are activated via `dotfiles.<name>.enable` boolean switches under a single flat namespace.
Each reusable module declares its own enable option and wraps its configuration in `mkIf`.
Host-only services live in `hosts/<host>/services/` and are imported directly.
Each service file includes its application settings and related reverse-proxy, firewall, and secret references.

`modules/hyprland/`, `modules/gaming/`, and `modules/audio/` own their Home and System implementations and checks.
The context registries in `modules/home-manager/default.nix` and `modules/nixos/default.nix` keep explicit import lists.
Home gaming defaults MangoHud on; Sunshine remains independently optional.
Audio keeps separate `dotfiles.pro-audio.enable` (Home applications) and `dotfiles.pipewire.enable` (System audio) switches.
Neither audio switch enables the other evaluation context.

### Atomic modules

Single-app modules that configure one application:

```nix
dotfiles.git.enable = true;
dotfiles.neovim.enable = true;
dotfiles.hyprland.enable = true;
```

### Groupings

Grouping modules compose several atomic modules under one switch. Members cascade via `mkDefault`, so a host can opt out of any member by setting it to `false`:

```nix
dotfiles.shell.enable = true;  # enables zsh, tmux, oh-my-posh, bat, btop, yazi, git 
dotfiles.git.enable = false;  # opt out of one member
```

### Cross-layer configuration

Apps that span both NixOS and Home Manager, such as Hyprland, get two switches with the same name in separate evaluation contexts.
Both must be enabled:

```nix
# configuration.nix (NixOS)
dotfiles.hyprland.enable = true;

# home.nix (Home Manager)
dotfiles.hyprland.enable = true;
```

The desktop's monitor settings are in `modules/hyprland/assets/settings.lua`.
Hyprland's four native Lua files use store-backed installation.
Home Manager adds the source of `entry.lua` to `hyprland.lua`.
Rebuild and activation install source edits and trigger an internal reload hook.
See the [Hyprland migration guide](docs/hyprland-summary.md) for ownership, checks, and the user-only activation, live smoke, and saved-path rollback procedure.

### Flake exports

The flake exports default module aggregations for external consumers. Each `default` imports all atomic modules in its layer, so consumers only need `default` and then enable what they want via `dotfiles.<name>.enable`:

- `homeManagerModules.default` imports all Home Manager modules.
- `nixosModules.default` imports all NixOS modules.
- `dotfilesPkgs.<system>` provides Custom Packages and flake-input packages.

External consumer example:

```nix
{
  inputs.dotfiles.url = "github:fveracoechea/dotfiles";
  inputs.nixpkgs.follows = "dotfiles/nixpkgs-latest";
  inputs.nixpkgs-stable.follows = "dotfiles/nixpkgs-stable";
  inputs.home-manager.follows = "dotfiles/home-manager";

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, dotfiles, ... }: {
    homeConfigurations."me@laptop" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = {
        dotfilesPkgs = dotfiles.dotfilesPkgs.x86_64-linux;
        pkgs-stable = nixpkgs-stable.legacyPackages.x86_64-linux;
      };
      modules = [
        dotfiles.homeManagerModules.default
        {
          dotfiles.shell.enable = true;
          dotfiles.neovim.enable = true;
        }
      ];
    };
  };
}
```

Use the matching Home Manager input and pass `pkgs-stable` for the shell's Release Channel coupling.
An older Home Manager pin may lack the OpenCode options declared by the module aggregate, even when coding agents are disabled.

## Installation

System builds and activation are user-only operations.
For the Hyprland language migration, follow the [migration test and recovery procedure](docs/hyprland-summary.md#user-only-activation-and-recovery) before a permanent `switch`.
It saves the active System path before `test`; `nixos-rebuild test --rollback` does not necessarily select that pre-test state.

1. **Clone the repository:**
   ```bash
    git clone https://github.com/fveracoechea/dotfiles.git ~/dotfiles
    cd ~/dotfiles
   ```

2. **Apply configuration:**

   **For NixOS:**
   ```bash
   sudo nixos-rebuild switch --flake .#nixos-desktop
   ```

3. **Test configuration (optional):**
   ```bash
    sudo nixos-rebuild test --flake .#nixos-desktop
   ```

## Repository structure

```
├── hosts/                    # Host-specific configurations
│   ├── nixos-desktop/       # NixOS desktop configuration
│   ├── homelab/             # LAN application server, host-local services/, and Home configuration
│   └── vps/                 # VPS control plane, host-local services/, networking, and storage
├── modules/                  # Reusable configuration modules
│   ├── core/                # Cross-cutting options (palette)
│   ├── coding-agents/       # Capability-owned Home implementation, packages, and checks
│   ├── nixos/               # Explicit System registry and unmigrated implementations
│   └── home-manager/        # Explicit Home registry and unmigrated implementations
├── packages/                # Custom packages (locally-built + wrapped from inputs)
├── config/                  # Native configuration for capabilities not yet migrated
└── flake.nix               # Main flake configuration
```

Reusable implementations migrate by capability, following ADR-0001 and ADR-0005.
The registries remain explicit and static.
Coding agents use `modules/coding-agents/home.nix` through `homeManagerModules.default` and `dotfiles.coding-agents.enable`.
That switch owns Herdr, OpenCode, Operator, Hunk, language tooling, and the held Nix MCP package and declaration.
It does not enable Git or lazygit; Hunk configures their pagers only when they are enabled.
Ordinary upstream definitions override the default OpenCode model and Herdr sidebar width.
Upstream list options merge contributions; use `lib.mkForce` only to deliberately replace an entire list.
Native capability assets belong beside their implementation; external instructions, skills, and Neovim sources retain their owners.

## Documentation

- [Server consolidation and deployment](docs/server-consolidation.md): preserved sources, evaluation gates, backups, and workflow retirement.
- [Hyprland configuration and migration](docs/hyprland-summary.md): native Lua ownership, verification, user-only activation, live tests, and rollback.
- **[Architecture Decision Records](docs/adr/)**: module structure, theming, the `dotfiles.*` enable namespace, and the nixpkgs channel split.
- [GLOSSARY.md](GLOSSARY.md) defines the repository's domain terms.

## License

This configuration is provided as-is for educational and personal use.
