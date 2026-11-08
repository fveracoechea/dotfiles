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

## Core tooling

### System and package management

- **[Nix Flakes](https://nixos.org/)**: Reproducible package management and system configuration
- **[Home Manager](https://github.com/nix-community/home-manager)**: User environment management

### Package channels

Two nixpkgs channels feed this flake, so Home packages can move without disturbing the System. See [ADR-0007](docs/adr/0007-split-nixpkgs-channels-by-package-owner.md).

| Channel             | Input                       | Branch                   | Builds                        |
| ------------------- | --------------------------- | ------------------------ | ----------------------------- |
| **Latest Channel**  | `nixpkgs-latest`            | `nixpkgs-unstable`       | Home-owned packages           |
| **Release Channel** | `nixpkgs-stable`     | `nixos-26.05`            | Linux System-owned packages   |

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

### Window management and desktop

- **[Hyprland](https://hyprland.org/)**: Dynamic tiling Wayland compositor
- **[DankMaterialShell](https://danklinux.com/)**: Desktop shell, launcher, notifications, clipboard, and lock screen
- **[Ly](https://github.com/fairyglade/ly)**: Display manager for UWSM-managed Hyprland and Steam sessions on NixOS
- **[Ghostty](https://mitchellh.com/ghostty)**: Fast, GPU-accelerated terminal emulator

### Development environment

- **[Neovim](https://neovim.io/)**: Extensible text editor with custom configuration
- **[TMUX](https://github.com/tmux/tmux)**: Terminal multiplexer with custom scripts
- **[Zsh](https://zsh.sourceforge.io/)** + **[Oh My Posh](https://ohmyposh.dev/)**: Enhanced shell experience
- **[LazyGit](https://github.com/jesseduffield/lazygit)**: Terminal UI for Git operations
- **[Yazi](https://yazi-rs.github.io/)**: Blazing fast terminal file manager

### Neovim plugins and tools

The Linux Neovim copy started from [this configuration](https://github.com/fveracoechea/macos-dotfiles/tree/9841b2b8aadfa22889712287a9630dc7d353b6dc/.config/nvim) and is maintained independently.
`vim.pack` owns plugins and pins them in `config/nvim/nvim-pack-lock.json`.
Nix supplies Neovim, language servers, formatters, and parser build tools.
The first launch needs network access to install plugins and compile parsers.
Nix and GraphQL language support remain enabled.
QML and Relay support are removed.

The desktop's `dotfiles.neovim.pluginLockPath` points to the tracked lockfile in `~/dotfiles`.
Home Manager links that file outside the Nix store, while Lua and snippets remain store-backed links in a writable directory.
Run `:lua vim.pack.update()` to update plugins, then review and commit the lockfile diff.
Activation does not copy an older lockfile over your edits.
Set `pluginLockPath` to your checkout if you clone elsewhere.
External consumers can omit it to keep a writable lockfile under their Neovim config directory.
Activation seeds that file only when absent and preserves later plugin updates.

Run `bash scripts/check-neovim-runtime.sh` for an isolated first-launch test with real plugin downloads and parser compilation.
It builds only the editor package, not the System.
The sandboxed flake smoke check instead uses parser fixtures from nixpkgs so it can run without network access.

### Coding agents

OpenCode comes from the Latest Channel's nixpkgs package, with Home Manager schema validation enabled.
Operator comes directly from its upstream flake, pinned to release `v2.2.2`.
Operator owns global agent instructions, its full skill catalog, and its OpenCode server plugin.
Herdr, Hunk, and the existing frontend-design skill remain separately managed.
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

Hex replaces Handy and comes from its `dev` flake input.
Its Home Manager user service starts with the Hyprland session and stops at logout.
It needs a working audio session and Vulkan driver.
Download a speech model after activation with `hex model install`, then open `hex` to select your microphone and settings.
Existing Handy settings and models stay on disk, but this configuration no longer modifies them.

Use `Ctrl+Space` for Hex's hold-to-talk desktop shortcut, or `Super+O` to toggle dictation.
The shortcut changes from Handy's `Alt+Space` because Hex documents focus and paste problems with Alt on Hyprland.
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

Modules are activated via `dotfiles.<name>.enable` boolean switches under a single flat namespace. Each module declares its own enable option and wraps its configuration in `mkIf`. Hosts flip switches instead of importing module paths.

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

The desktop's monitor settings are in `config/hypr/settings.lua`.
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
          dotfiles.neovim.pluginLockPath = "/home/me/dotfiles/config/nvim/nvim-pack-lock.json";
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
│   └── nixos-desktop/       # NixOS desktop configuration
├── modules/                  # Reusable configuration modules
│   ├── core/                # Cross-cutting options (palette)
│   ├── nixos/               # NixOS-specific modules
│   └── home-manager/        # User environment modules
├── packages/                # Custom packages (locally-built + wrapped from inputs)
├── config/                  # Store-backed native app configuration, including hypr/ and nvim/
└── flake.nix               # Main flake configuration
```

## Documentation

- [Hyprland configuration and migration](docs/hyprland-summary.md): native Lua ownership, verification, user-only activation, live tests, and rollback.
- **[Architecture Decision Records](docs/adr/)**: module structure, theming, the `dotfiles.*` enable namespace, and the nixpkgs channel split.
- [CONTEXT.md](CONTEXT.md) defines the repository's domain terms.

## License

This configuration is provided as-is for educational and personal use.
