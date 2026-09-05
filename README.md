# Development Environment Configuration

A NixOS/nix-darwin dotfiles configuration providing a consistent, reproducible
development environment across macOS and Linux using Nix flakes.

## Main Features

- **Keyboard Focused**: Efficient tiling window management with Hyprland
- **Minimal Distractions**: Clean, focused interface design
- **Configuration as Code**: Everything managed through Nix flakes
- **Modular Configuration**: Enable apps and services via `dotfiles.<name>.enable` switches under a unified namespace
- **Highly Customizable**: Groupings (`dotfiles.shell`, `dotfiles.gaming`) compose atomic modules with `mkDefault` opt-out
- **Reproducible**: Identical environments across multiple machines
- **Cross-Platform**: Supports both NixOS and macOS (nix-darwin)
- **Reusable**: Flake exports `homeManagerModules`, `nixosModules`, and `darwinModules` for external consumers

## Supported Systems

- **NixOS Desktop** (`nixos-desktop`): x86_64-linux gaming/development setup
- **MacBook Pro** (`macbook-pro`): aarch64-darwin mobile development environment

## Core Tooling

### System & Package Management

- **[Nix Flakes](https://nixos.org/)**: Reproducible package management and system configuration
- **[Home Manager](https://github.com/nix-community/home-manager)**: User environment management

### Package channels

Two nixpkgs channels feed this flake, so Home packages can move without disturbing the System. See [ADR-0007](docs/adr/0007-split-nixpkgs-channels-by-package-owner.md).

| Channel             | Input                       | Branch                   | Builds                        |
| ------------------- | --------------------------- | ------------------------ | ----------------------------- |
| **Latest Channel**  | `nixpkgs-latest`            | `nixpkgs-unstable`       | Home-owned packages           |
| **Release Channel** | `nixpkgs-stable`     | `nixos-26.05`            | Linux System-owned packages   |
| **Release Channel** | `nixpkgs-stable-darwin`    | `nixpkgs-26.05-darwin`   | macOS System-owned packages   |

Package ownership decides the channel. Version-Coupled Packages follow their
partner, Spotify uses the Latest Channel despite its darwin System location,
and a broken Latest package can use a documented Channel Hold.

`nix-darwin` is pinned to `nix-darwin-26.05` because it asserts that its own
branch corresponds to the Nixpkgs branch it evaluates against.

```bash
# Newer coding agents, CLI, and apps. Leaves the kernel and compositor alone.
nix flake update nixpkgs-latest

# Move the System. Do this deliberately and test both hosts.
nix flake update nixpkgs-stable nixpkgs-stable-darwin nix-darwin

# One tool only, when it has its own input.
nix flake update herdr
```

When a release lands, move all three release refs together:
`nixpkgs-stable` to `nixos-YY.MM`, `nixpkgs-stable-darwin` to
`nixpkgs-YY.MM-darwin`, and `nix-darwin` to `nix-darwin-YY.MM`.

### Window Management & Desktop

- **[Hyprland](https://hyprland.org/)**: Dynamic tiling Wayland compositor
- **[Ultrashell](https://github.com/fveracoechea/ultrashell)**: Feature-rich status bar
- **[SDDM](https://github.com/sddm/sddm)**: Display manager (NixOS)
- **[Ghostty](https://mitchellh.com/ghostty)**: Fast, GPU-accelerated terminal emulator

### Development Environment

- **[Neovim](https://neovim.io/)**: Extensible text editor with custom configuration
- **[TMUX](https://github.com/tmux/tmux)**: Terminal multiplexer with custom scripts
- **[Zsh](https://zsh.sourceforge.io/)** + **[Oh My Posh](https://ohmyposh.dev/)**: Enhanced shell experience
- **[LazyGit](https://github.com/jesseduffield/lazygit)**: Terminal UI for Git operations
- **[Yazi](https://yazi-rs.github.io/)**: Blazing fast terminal file manager

### Additional Tools

- **[Volta](https://volta.sh/)**: JavaScript toolchain manager
- **[Bat](https://github.com/sharkdp/bat)**: Enhanced `cat` with syntax highlighting
- **[Fuzzel](https://codeberg.org/dnkl/fuzzel)**: Application launcher for Wayland
- **[Karabiner Elements](https://karabiner-elements.pqrs.org/)**: Keyboard customization (macOS)

## Theming

- **[Catppuccin Mocha](https://catppuccin.com/)**: Consistent pastel theme across all applications, sourced from a single palette via `config.dotfiles.palette`
- **Custom wallpapers**: Curated collection in `assets/`

## Module System

Modules are activated via `dotfiles.<name>.enable` boolean switches under a single flat namespace. Each module declares its own enable option and wraps its configuration in `mkIf`. Hosts flip switches instead of importing module paths.

### Atomic Modules

Single-app modules that configure one application:

```nix
dotfiles.git.enable = true;
dotfiles.neovim.enable = true;
dotfiles.fuzzel.enable = true;
```

### Groupings

Grouping modules compose several atomic modules under one switch. Members cascade via `mkDefault`, so a host can opt out of any member by setting it to `false`:

```nix
dotfiles.shell.enable = true;  # enables zsh, tmux, oh-my-posh, bat, btop, yazi, git 
dotfiles.git.enable = false;  # opt out of one member
```

### Cross-Layer

Apps that span both NixOS and Home Manager (e.g. Hyprland) get two switches with the same name in separate eval contexts — both must be enabled:

```nix
# configuration.nix (NixOS)
dotfiles.hyprland.enable = true;

# home.nix (Home Manager)
dotfiles.hyprland.enable = true;
dotfiles.hyprland.monitors = [ "DP-1, 5120x1440@119.98Hz, auto, auto, bitdepth, 8, cm, auto" ];
```

### Flake Exports

The flake exports default module aggregations for external consumers. Each `default` imports all atomic modules in its layer, so consumers only need `default` and then enable what they want via `dotfiles.<name>.enable`:

- `homeManagerModules.default` — all home-manager modules
- `nixosModules.default` — all NixOS modules
- `darwinModules.default` — all darwin modules
- `dotfilesPkgs.<system>` — packages this flake provides (locally-built + wrapped from inputs)

External consumer example:

```nix
{
  inputs.dotfiles.url = "github:fveracoechea/dotfiles";
  inputs.home-manager.url = "github:nix-community/home-manager";

  outputs = { self, nixpkgs, home-manager, dotfiles, ... }: {
    homeConfigurations."me@laptop" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = {
        dotfilesPkgs = dotfiles.dotfilesPkgs.x86_64-linux;
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

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/fveracoechea/dotfiles.git ~/.config/dotfiles
   cd ~/.config/dotfiles
   ```

2. **Apply configuration:**

   **For NixOS:**
   ```bash
   sudo nixos-rebuild switch --flake .#nixos-desktop
   ```

   **For macOS:**
   ```bash
   darwin-rebuild switch --flake .#macbook-pro
   ```

3. **Test configuration (optional):**
   ```bash
   # NixOS
   sudo nixos-rebuild test --flake .#nixos-desktop

   # macOS
   darwin-rebuild check --flake .#macbook-pro
   ```

## Repository Structure

```
├── hosts/                    # Host-specific configurations
│   ├── nixos-desktop/       # NixOS desktop configuration
│   └── macbook-pro/         # macOS configuration
├── modules/                  # Reusable configuration modules
│   ├── core/                # Cross-cutting options (palette)
│   ├── nixos/               # NixOS-specific modules
│   ├── darwin/              # macOS-specific modules
│   └── home-manager/        # User environment modules
├── packages/                # Custom packages (locally-built + wrapped from inputs)
└── flake.nix               # Main flake configuration
```

## Documentation

- **[Architecture Decision Records](docs/adr/)** — decisions on module structure, theming, macOS package split, the `dotfiles.*` enable namespace, and the nixpkgs channel split.
- **[CONTEXT.md](CONTEXT.md)** — domain glossary for the repository.

## License

This configuration is provided as-is for educational and personal use.
