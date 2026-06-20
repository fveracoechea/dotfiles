# Handoff: dotfiles flake refactor

## Goal

Refactor the dotfiles Nix flake from an "import modules" model to an "enable configurations" model via a `dotfiles.*` option namespace. Also expose the flake's modules as importable outputs for external consumers.

**Scope of this refactor (initial implementation):** pure mechanical migration of the *current* config to the new format. Hyprland stays in Nix (its 11 sub-files stay as-is, just wrapped in the new `dotfiles.hyprland.enable` pattern). Neovim stays the external `neovim-config` flake input. The Hyprland→lua migration and Neovim in-housing are **deferred** to separate future efforts (sketched in "Deferred work" at the end of this doc).

**Out of scope:** multi-theme support (theming stays as today — single hardcoded catppuccin-mocha palette, ADR 0002 unchanged). Hyprland lua migration. Neovim in-housing.

This document is a **plan only** — no code changes have been made yet (only `CONTEXT.md` has been updated with new glossary terms). The implementing agent should treat this as the authoritative spec for the refactor.

## Repository

- Path: `/home/fveracoechea/dotfiles`
- Type: NixOS/nix-darwin dotfiles flake
- AGENTS.md rules: never build system config (user does that); test with `nixos-rebuild test --flake .#nixos-desktop` or `darwin-rebuild check --flake .#macbook-pro`; check flake with `nix flake check`.
- Issue tracker: GitHub Issues via `gh` CLI. Triage labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`.
- Domain docs: `CONTEXT.md` at root (already updated with refactor terms — see "Glossary updates" below), `docs/adr/` for ADRs.

## Current state (before refactor)

- `flake.nix` defines two hosts: `nixos-desktop` (x86_64-linux) and `macbook-pro` (aarch64-darwin). Each host's `configuration.nix` and `home.nix` import modules from `modules/{nixos,darwin,home-manager}/` via `imports = [...]`.
- `specialArgs` injects `{ inputs, system, customUtils, customPkgs }` into all modules.
- `customUtils` (in `utils/`) contains `catppuccin` (palette attrset) and `monitors` (catalog of monitor spec strings).
- `customPkgs` (built by `packages/default.nix` from `pkgs`) contains locally-built packages (`railway`, `dev-manager-desktop`).
- External flake input `neovim-config` provides the Neovim config (stays as-is in this refactor — in-housing is deferred).
- Hyprland config is in Nix (11 sub-files under `modules/home-manager/hyprland/`). Stays as-is in this refactor — migration to the new lua config format (Hyprland 0.55+) is deferred.
- `modules/home-manager/tmux/` and `modules/home-manager/desktop-entries/` already co-locate non-Nix source files (`.conf`, icons) alongside Nix wiring — this is the established co-location precedent.
- Existing ADRs in `docs/adr/`:
  - `0001-thin-hosts-with-focused-modules.md`
  - `0002-per-application-manual-theming.md`
  - `0003-homebrew-and-home-manager-split-on-macos.md`

## Decisions (all locked during grilling session)

### 1. Namespace: `dotfiles.*`

- Every module exposes `options.dotfiles.<name>.enable = lib.mkEnableOption "...";`.
- Hosts activate by setting `dotfiles.<name>.enable = true;` (no more `imports = [...]` of module paths in hosts).
- One flat namespace; no separate `bundles.*` or `configurations.*`. Some entries are single apps, some are groupings — distinguished by name only, no marker.
- Examples: `dotfiles.neovim.enable`, `dotfiles.shell.enable` (grouping), `dotfiles.gaming.enable` (grouping), `dotfiles.git.enable`.

### 2. Module contract: `enable` gates body, overrides via upstream options

- Each module declares `options.dotfiles.<name>.enable` and wraps its body in `config = lib.mkIf config.dotfiles.<name>.enable { ... };`.
- Module bakes in personal defaults. Hosts override via the upstream HM/nixpkgs option directly (HM merges), NOT via a re-exposed custom settings surface.
- Do NOT re-expose upstream options under `dotfiles.<name>.*` — that's the classic wrapper-repo anti-pattern. Only `.enable` (plus the cross-cutting `dotfiles.palette`/`dotfiles.monitors` from core, see below).

### 3. Naming convention: implicit (no markers for groupings vs atomics)

- Groupings (`shell`, `gaming`, `gui`) and atomics (`git`, `neovim`, `hyprland`) live side by side under `dotfiles.*`.
- Granularity is discoverable by reading the module or its `mkEnableOption` doc string.
- A name that reads as a concern/category (`shell`, `gaming`, `dev`, `gui`) is a grouping; a name that reads as an app name (`git`, `neovim`, `fuzzel`) is atomic.

### 4. No shared accumulator options (no `dotfiles.unfreePackages`)

- Modules that need an unfree or insecure package declare `nixpkgs.config.permittedInsecurePackages` / `nixpkgs.config.allowUnfree` directly where they're used. Nixpkgs merges across modules.
- No custom accumulator list to maintain. Audit via `rg permittedInsecurePackages` or `nix flake check`.

### 5. Module granularity: one top-level module = one `dotfiles.<name>` switch

- A directory module (e.g. `modules/home-manager/hyprland/`) collapses to ONE switch (`dotfiles.hyprland.enable`). Internally it can import its own sub-files, but from the host's view it's on/off.
- If a sub-concern later needs independent toggling, split it into its own top-level module — do NOT nest options.

### 6. Source file co-location: non-Nix source stays in the module dir

- Non-Nix source files (lua, conf, icons) live alongside the Nix wiring in the module directory — NOT in a separate top-level `config/` or `sources/` dir.
- Precedent: `modules/home-manager/tmux/{default.nix, tmux.conf, tmux.powerkit.conf}` and `modules/home-manager/desktop-entries/{default.nix, icons/}`.
- Convention for multi-file trees: if a module has multiple non-Nix source files, they go under a per-language subdir (e.g. `lua/`) inside the module dir. If only a single file, it sits flat (no subdir). The `default.nix` (Nix wiring) always sits at the module-dir root.
- Applies today to: tmux (flat: `tmux/default.nix` + `tmux/tmux.conf`), desktop-entries (`default.nix` + `icons/`). The `lua/` subdir convention is documented here for the *deferred* Hyprland-lua and Neovim-in-housing work; no `lua/` dirs are created in this refactor.

### 7. Kill `customUtils`; move palette and monitors into `config`

- Delete the `utils/` directory entirely (`default.nix`, `catppuccin.nix`, `monitors.nix`).
- `customUtils.catppuccin` → `config.dotfiles.palette` — a plain attrset option with a hardcoded default of catppuccin-mocha (the data file `utils/catppuccin.nix` content moves into `modules/core/palette.nix` as the default value). Per-app modules read `config.dotfiles.palette.base` etc.
- `customUtils.monitors` → `config.dotfiles.monitors` — a host-declared `listOf str` option. Hosts declare their monitors inline (e.g. `dotfiles.monitors = [ "DP-1, 5120x1440@119.98Hz, auto, auto, bitdepth, 8, cm, auto" ];`). The current `utils/monitors.nix` catalog (a lookup of every monitor ever owned) is DELETED — it was host-specific knowledge pretending to be shared.
- Theming (multi-theme support) is DEFERRED to a future refactor. For now: catppuccin-mocha hardcoded, single palette. When theming lands later, `config.dotfiles.palette` becomes the thing the theme selector populates (readOnly, sourced from selector), and per-app modules don't change.

### 8. `customPkgs` → `dotfilesPkgs`; absorb non-nixpkgs inputs

- Rename `customPkgs` to `dotfilesPkgs` (inject via `specialArgs` under that name). Reasoning: aligns with `dotfiles.*` namespace, scopes the concept to this flake.
- Extend `packages/default.nix` to also wrap non-nixpkgs flake inputs so modules never touch `inputs`/`system` for *packages*:
  ```nix
  # packages/default.nix (new shape)
  { pkgs, inputs, system }: {
    # locally-built
    railway = pkgs.callPackage ./railway.nix {};
    dev-manager-desktop = pkgs.callPackage ./dev-manager-desktop.nix {};
    # wrapped from inputs
    hyprland = inputs.hyprland.packages.${system}.hyprland;
    hyprland-portal = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
    tmux-powerkit = inputs.tmux-powerkit.packages.${system}.default;
  }
  ```
- No overlays (explicit constraint from user).
- Modules take `{ lib, config, pkgs, dotfilesPkgs, ... }` for package access — they do NOT take `system`. `system` is dropped from `specialArgs` entirely.
- **`inputs` stays in `specialArgs`** as a narrow exception: the neovim wrapper module needs `inputs.neovim-config.homeManagerModules.default` to import the external flake's HM *module* (not a package — modules can't be wrapped into `dotfilesPkgs`). Rule: modules SHOULD read packages via `dotfilesPkgs`; they may use `inputs` ONLY for importing external flake modules (rare). When Neovim is in-housed later, `inputs` can be dropped from `specialArgs` entirely.

### 9. Flake exports: per-name + aggregate, `.default` convention

- Flake outputs `homeManagerModules`, `nixosModules`, `darwinModules` — each an attrset.
- Per-name entries keyed by module name: `homeManagerModules.git`, `homeManagerModules.shell`, `homeManagerModules.neovim`, etc.
- Aggregate under `.default`: `homeManagerModules.default = ./modules/home-manager/default.nix;` — this file imports the core modules + every per-name module in that layer, so the full `dotfiles.*` option tree is populated for a consumer who imports just `.default`.
- Same shape for all three layers (symmetry).
- Aggregate imports use **relative paths** (`./git.nix`), not flake-output self-references.

### 10. Aggregate file: `default.nix`, hand-maintained

- One `default.nix` per layer dir: `modules/home-manager/default.nix`, `modules/nixos/default.nix`, `modules/darwin/default.nix`.
- Each is a hand-maintained `imports = [...]` list of core modules + every per-name module in that layer.
- The HM aggregate imports `../core/palette.nix` and `../core/monitors.nix` FIRST (so their options exist when per-app modules read them), then per-name modules.
- This file doubles as the module index — a newcomer reads it to see "what apps does this flake configure?".
- A grouping (e.g. `shell.nix`) is ONE entry in the aggregate; the grouping file imports its members internally (the aggregate is an index of top-level switches, not of every file).

### 11. Grouping composition: `mkDefault` cascade

- A grouping module imports its members (so their `dotfiles.*.enable` options exist) and sets each member's `enable` to `mkDefault true` under its own `mkIf`:
  ```nix
  # modules/home-manager/shell.nix
  { lib, config, ... }: {
    imports = [ ./zsh.nix ./tmux.nix ./lazygit.nix ./lazydocker.nix ./yazi.nix ./bat.nix ./btop.nix ./oh-my-posh.nix ./git.nix ];
    options.dotfiles.shell.enable = lib.mkEnableOption "shell suite (zsh, tmux, oh-my-posh, bat, btop, yazi, git, lazygit, lazydocker)";
    config = lib.mkIf config.dotfiles.shell.enable {
      dotfiles.zsh.enable = lib.mkDefault true;
      dotfiles.tmux.enable = lib.mkDefault true;
      dotfiles.oh-my-posh.enable = lib.mkDefault true;
      dotfiles.bat.enable = lib.mkDefault true;
      dotfiles.btop.enable = lib.mkDefault true;
      dotfiles.yazi.enable = lib.mkDefault true;
      dotfiles.git.enable = lib.mkDefault true;
      dotfiles.lazygit.enable = lib.mkDefault true;
      dotfiles.lazydocker.enable = lib.mkDefault true;
    };
  }
  ```
- Host can opt out of any member: `dotfiles.shell.enable = true; dotfiles.lazydocker.enable = false;`.
- Host can also enable a member directly without the grouping: `dotfiles.zsh.enable = true;`.

### 12. Inter-module dependencies: assertions, sparingly

- Use `assertions` for genuinely broken combinations (e.g. gaming without gui → broken). Pattern from the example repo:
  ```nix
  assertions = [{
    assertion = config.dotfiles.gui.enable;
    message = "you probably want to enable gui for gaming";
  }];
  ```
- Rule: assert ONLY when the config CANNOT function, not when it's merely suboptimal.
- Cross-layer assertions (NixOS module asserting an HM-side `dotfiles.*.enable`) do NOT work — NixOS and HM have separate eval contexts. Cross-layer prerequisites are documented in `mkEnableOption` descriptions only, NOT enforced.

### 13. No bridge between NixOS and HM contexts

- Apps that span both NixOS and HM (hyprland, gaming, zsh) get TWO switches, same name, different contexts: `dotfiles.hyprland.enable` in `configuration.nix` (NixOS) AND `dotfiles.hyprland.enable` in `home.nix` (HM). They're unrelated options in separate eval trees that happen to share a name.
- NO bridging via `home-manager.users.<user>.dotfiles.<name>.enable = mkDefault true`. Reasoning (user decision): keep things clean, rely on docs.
- NO `dotfiles.user` option (not needed without the bridge).
- `mkEnableOption` descriptions document prerequisites: e.g. `mkEnableOption "Hyprland home config (also enable dotfiles.hyprland in configuration.nix)"`.

### 14. Package-list policy: two-tier, no `dotfiles.dev` bundle

- **Tier 1 — Apps with HM config** → get a `dotfiles.*` module. The module installs its own packages (via `home.packages` or `programs.*` inside the module body).
- **Tier 2 — Host-specific one-offs** → raw `home.packages` in the host (e.g. slack, vesktop, chrome, python3, postman, beekeeper-studio, obs-studio on desktop; glab, redis, claude-code on laptop).
- NO `dotfiles.dev` / `dotfiles.cli` bundle for shared leaf packages. Reasoning: the empirically-derived shared set was only 5 packages (watchman, ripgrep, just, wireguard-tools, agent-browser) — not worth a module. If duplication stings later (3+ hosts), promote `dotfiles.dev` then.
- Any package that has HM config gets its own module regardless of how many hosts want it (lazygit, lazydocker, yazi, bat, btop all have HM config → tier 1).

### 15. Module classification table (locked)

#### `modules/home-manager/` (shared across NixOS + darwin)

| Current module | Proposed `dotfiles.*` | Type | Notes |
|---|---|---|---|
| `git.nix` | `dotfiles.git` | atomic | EXTRACT lazygit out (currently `programs.lazygit` lives in git.nix:39-42) |
| `lazygit.nix` (NEW) | `dotfiles.lazygit` | atomic | extracted from git.nix; has HM config via `programs.lazygit` |
| `lazydocker.nix` (NEW) | `dotfiles.lazydocker` | atomic | new module; has HM config via `programs.lazydocker` |
| `zsh.nix` | `dotfiles.zsh` | atomic | |
| `tmux/` | `dotfiles.tmux` | atomic | co-located `tmux.conf`, `tmux.powerkit.conf` |
| `bat.nix` | `dotfiles.bat` | atomic | |
| `btop.nix` | `dotfiles.btop` | atomic | |
| `yazi.nix` | `dotfiles.yazi` | atomic | |
| `oh-my-posh.nix` | `dotfiles.oh-my-posh` | atomic | |
| `shell.nix` (NEW) | `dotfiles.shell` | **grouping** | cascades to the 9 above via mkDefault |
| `gtk.nix` | `dotfiles.gtk` | atomic | |
| `volta.nix` | `dotfiles.volta` | atomic | |
| `pro-audio.nix` | `dotfiles.pro-audio` | atomic | |
| `fuzzel.nix` | `dotfiles.fuzzel` | atomic | rewrites `customUtils.catppuccin` → `config.dotfiles.palette` |
| `ghostty.nix` | `dotfiles.ghostty` | atomic | |
| `hyprland/` | `dotfiles.hyprland` | atomic | Stays in Nix for this refactor (11 sub-files unchanged, just wrapped in `dotfiles.hyprland.enable` + `mkIf`). Migration to lua is deferred. |
| `sunshine.nix` | `dotfiles.sunshine` | atomic | |
| `opencode/` | `dotfiles.opencode` | atomic | has `command/` subdir |
| `desktop-entries/` | `dotfiles.desktop-entries` | atomic | bundle of .desktop files + icons/, but one switch |
| `fonts.nix` | `dotfiles.fonts` | atomic | |
| `spotify.nix` | `dotfiles.spotify` | atomic | |
| `karabiner.nix` | `dotfiles.karabiner` | atomic | darwin-only |
| `ssh.nix` | `dotfiles.ssh` | atomic | |
| `aerospace.nix` | `dotfiles.aerospace` | atomic | darwin-only |

**Note on Neovim:** in this refactor, Neovim stays the external `neovim-config` flake input. The host's `home.nix` keeps `imports = [ inputs.neovim-config.homeManagerModules.default ];` OR (cleaner) a thin `modules/home-manager/neovim.nix` wrapper is created that imports the external module and exposes `dotfiles.neovim.enable` — this keeps the host's `dotfiles.*.enable` surface uniform without in-housing the lua config. The wrapper approach is recommended so the host reads `dotfiles.neovim.enable = true;` like every other app. In-housing the lua source is deferred.

#### `modules/nixos/`

| Current | Proposed `dotfiles.*` | Type | Notes |
|---|---|---|---|
| `bootloader.nix` | `dotfiles.bootloader` | atomic | |
| `displayManager.nix` | `dotfiles.display-manager` | atomic | kebab-case the name |
| `miscellaneous.nix` | `dotfiles.misc` | atomic | |
| `zsh-shell.nix` | `dotfiles.zsh-shell` | atomic | NixOS-side zsh; distinct from HM `dotfiles.zsh` |
| `nix-ld.nix` | `dotfiles.nix-ld` | atomic | |
| `timezone.nix` | `dotfiles.timezone` | atomic | |
| `pipewire.nix` | `dotfiles.pipewire` | atomic | |
| `gaming.nix` | `dotfiles.gaming` | **grouping** | enables steam, gamescope, etc. via mkDefault |
| `hyprland.nix` | `dotfiles.hyprland` | atomic | NixOS-side; shares name with HM `dotfiles.hyprland` (separate eval context, no collision) |
| `ollama.nix` | `dotfiles.ollama` | atomic | currently commented out in host |
| `networking.nix` | `dotfiles.networking` | atomic | |

#### `modules/darwin/`

| Current | Proposed `dotfiles.*` | Type |
|---|---|---|
| `homebrew.nix` | `dotfiles.homebrew` | atomic |
| `system-defaults.nix` | `dotfiles.system-defaults` | atomic |
| `zsh-shell.nix` | `dotfiles.zsh-shell` | atomic |

### 16. Keep `modules/` directory name (do NOT rename to `config/`)

- `modules/` is the ecosystem convention (NixOS, nix-darwin, HM all use it).
- "config" is overloaded in Nix (every module has a `config` attr); a `config/` dir collides semantically.
- Co-located source files (lua, conf) inside module dirs don't change this — the primary content of every dir under `modules/` is a Nix module.

## Target directory structure

```
/
├── CONTEXT.md                      # updated with new glossary terms
├── flake.nix                       # restructured: exports homeManagerModules/nixosModules/darwinModules + dotfilesPkgs
├── packages/
│   ├── default.nix                 # extended: takes { pkgs, inputs, system }, wraps non-nixpkgs inputs
│   ├── railway.nix
│   └── dev-manager-desktop.nix
├── modules/
│   ├── core/                       # NEW: cross-cutting options shared by all dotfiles.* modules
│   │   ├── palette.nix             # options.dotfiles.palette (hardcoded catppuccin-mocha default)
│   │   └── monitors.nix            # options.dotfiles.monitors (host-declared list of str)
│   ├── nixos/
│   │   ├── default.nix             # NEW: aggregate (imports all per-name in this layer)
│   │   ├── bootloader.nix
│   │   ├── display-manager.nix     # renamed from displayManager.nix
│   │   ├── misc.nix                # renamed from miscellaneous.nix
│   │   ├── zsh-shell.nix
│   │   ├── nix-ld.nix
│   │   ├── timezone.nix
│   │   ├── pipewire.nix
│   │   ├── gaming.nix              # grouping
│   │   ├── hyprland.nix
│   │   ├── ollama.nix
│   │   └── networking.nix
│   ├── darwin/
│   │   ├── default.nix             # NEW: aggregate
│   │   ├── homebrew.nix
│   │   ├── system-defaults.nix
│   │   └── zsh-shell.nix
│   └── home-manager/
│       ├── default.nix             # NEW: aggregate (imports core/ + all per-name)
│       ├── git.nix                 # lazygit extracted out
│       ├── lazygit.nix             # NEW: extracted from git.nix
│       ├── lazydocker.nix          # NEW
│       ├── zsh.nix
│       ├── tmux/
│       │   ├── default.nix
│       │   ├── tmux.conf
│       │   └── tmux.powerkit.conf
│       ├── bat.nix
│       ├── btop.nix
│       ├── yazi.nix
│       ├── oh-my-posh.nix
│       ├── shell.nix               # NEW: grouping
│       ├── gtk.nix
│       ├── volta.nix
│       ├── pro-audio.nix
│       ├── fuzzel.nix
│       ├── ghostty.nix
│       ├── hyprland/
│       │   └── default.nix          # stays Nix (11 sub-files unchanged) for this refactor; wrapped in dotfiles.hyprland.enable + mkIf
│       ├── sunshine.nix
│       ├── opencode/
│       │   ├── default.nix
│       │   └── command/
│       ├── desktop-entries/
│       │   ├── default.nix
│       │   └── icons/
│       ├── fonts.nix
│       ├── spotify.nix
│       ├── karabiner.nix
│       ├── ssh.nix
│       ├── neovim.nix               # NEW: thin wrapper that imports the external neovim-config flake input + exposes dotfiles.neovim.enable
│       └── aerospace.nix
├── hosts/
│   ├── nixos-desktop/
│   │   ├── configuration.nix      # rewritten: dotfiles.*.enable switches
│   │   ├── home.nix               # rewritten: dotfiles.*.enable switches
│   │   └── hardware-configuration.nix  # unchanged
│   └── macbook-pro/
│       ├── configuration.nix      # rewritten
│       └── home.nix               # rewritten
├── docs/
│   └── adr/                       # new ADR for this refactor (see "ADRs to write" below)
└── assets/                         # unchanged
```

**Deleted:**
- `utils/` directory entirely (`default.nix`, `catppuccin.nix`, `monitors.nix`).

## Target `flake.nix` shape

```nix
{
  description = "Personal NixOS/nix-darwin dotfiles flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = "github:hyprwm/Hyprland?ref=refs/tags/v0.55.4";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    ultrashell.url = "github:fveracoechea/ultrashell";
    ultrashell.inputs.nixpkgs.follows = "nixpkgs";
    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    mcp-servers-nix.inputs.nixpkgs.follows = "nixpkgs";
    tmux-powerkit.url = "github:fabioluciano/tmux-powerkit";
    tmux-powerkit.inputs.nixpkgs.follows = "nixpkgs";
    neovim-config.url = "github:fveracoechea/neovim-nix-config";
    neovim-config.inputs.nixpkgs.follows = "nixpkgs";
    # NOTE: neovim-config input KEPT (in-housing deferred)
  };

  outputs = { nixpkgs, home-manager, nix-darwin, ... }@inputs: let
    supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];
    dotfilesPkgsFor = system: import ./packages { inherit inputs system; pkgs = nixpkgs.legacyPackages.${system}; };

    # Per-layer module attrsets for flake export
    homeManagerModules = {
      default = ./modules/home-manager/default.nix;
      git = ./modules/home-manager/git.nix;
      shell = ./modules/home-manager/shell.nix;
      neovim = ./modules/home-manager/neovim.nix;       # thin wrapper over the external neovim-config input
      hyprland = ./modules/home-manager/hyprland/default.nix;
      # ... one entry per per-name module
    };
    nixosModules = {
      default = ./modules/nixos/default.nix;
      bootloader = ./modules/nixos/bootloader.nix;
      hyprland = ./modules/nixos/hyprland.nix;
      gaming = ./modules/nixos/gaming.nix;
      # ... one entry per per-name module
    };
    darwinModules = {
      default = ./modules/darwin/default.nix;
      homebrew = ./modules/darwin/homebrew.nix;
      # ... one entry per per-name module
    };
  in {
    inherit homeManagerModules nixosModules darwinModules;

    # dotfilesPkgs exported per-system for external consumers
    dotfilesPkgs = builtins.listToAttrs (map (system: {
      name = system;
      value = dotfilesPkgsFor system;
    }) supportedSystems);

    # Host configurations
    nixosConfigurations.nixos-desktop = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      specialArgs = { dotfilesPkgs = dotfilesPkgsFor system; inherit inputs; };
      modules = [
        nixosModules.default
        ./hosts/nixos-desktop/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.users.fveracoechea = import ./hosts/nixos-desktop/home.nix;
          home-manager.extraSpecialArgs = specialArgs;
        }
      ];
    };

    darwinConfigurations."macbook-pro" = nix-darwin.lib.darwinSystem rec {
      system = "aarch64-darwin";
      specialArgs = { dotfilesPkgs = dotfilesPkgsFor system; inherit inputs; };
      modules = [
        darwinModules.default
        ./hosts/macbook-pro/configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.users.franciscoveracoechea = import ./hosts/macbook-pro/home.nix;
          home-manager.extraSpecialArgs = specialArgs;
        }
      ];
    };
  };
}
```

**Notes on flake.nix:**
- `system` is NOT in `specialArgs` anymore. `dotfilesPkgs` is in `specialArgs`. `inputs` STAYS in `specialArgs` — it's needed by the neovim wrapper module (which imports `inputs.neovim-config.homeManagerModules.default`). This is a narrow exception to the "modules don't touch inputs" rule: modules SHOULD read packages via `dotfilesPkgs`, but may use `inputs` for importing external flake *modules* (not packages). When Neovim is in-housed later, `inputs` can be dropped from `specialArgs` entirely.
- External consumers: pass `dotfilesPkgs = dotfiles.dotfilesPkgs.${system}` (required) and `inputs = { neovim-config = ...; }` (only if they enable `dotfiles.neovim`).
- The aggregate (`nixosModules.default` / `homeManagerModules.default` / `darwinModules.default`) replaces the old `imports = [ ./modules/... ]` lists in hosts. Hosts no longer import module paths; they set `dotfiles.*.enable`.
- `customUtils` is gone from `specialArgs`.
- `neovim-config` input is KEPT (in-housing deferred). The thin `modules/home-manager/neovim.nix` wrapper imports `inputs.neovim-config.homeManagerModules.default` and exposes `dotfiles.neovim.enable`. When Neovim is in-housed later, this wrapper becomes the real module and the `inputs` exception disappears.
- Some modules (e.g. `modules/nixos/hyprland.nix`) previously read `inputs.hyprland.packages.${system}` — after refactor they read `dotfilesPkgs.hyprland` instead (the wrapping happens in `packages/default.nix`).

## Target module shape (concrete example)

```nix
# modules/home-manager/fuzzel.nix
{ lib, config, ... }:
let
  p = config.dotfiles.palette;
  toHex = color: "${lib.substring 1 6 (lib.strings.toLower color)}ff";
in {
  options.dotfiles.fuzzel.enable = lib.mkEnableOption "fuzzel launcher";

  config = lib.mkIf config.dotfiles.fuzzel.enable {
    programs.fuzzel = {
      enable = true;
      settings = {
        main = { /* ... */ };
        colors = {
          background = toHex p.base;
          text = toHex p.text;
          prompt = toHex p.subtext1;
          # ... (same as today, reading from p instead of customUtils.catppuccin)
        };
      };
    };
  };
}
```

## Target host shape (concrete example)

```nix
# hosts/nixos-desktop/home.nix
{ pkgs, dotfilesPkgs, ... }: {
  dotfiles = {
    shell.enable = true;
    git.enable = true;
    gtk.enable = true;
    volta.enable = true;
    pro-audio.enable = true;
    fuzzel.enable = true;
    ghostty.enable = true;
    hyprland.enable = true;
    sunshine.enable = true;
    opencode.enable = true;
    desktop-entries.enable = true;
    fonts.enable = true;
    spotify.enable = true;
    neovim.enable = true;
  };

  home.username = "fveracoechea";
  home.homeDirectory = "/home/fveracoechea";
  home.file.".face".source = ../../assets/face.jpg;
  home.file.".face.icon".source = ../../assets/face.jpg;

  home.packages = with pkgs; [
    slack vesktop google-chrome kooha python3 nurl postman lutgen
    beekeeper-studio openlinkhub docker-compose zettlr tiny-rdm obs-studio
  ] ++ [ dotfilesPkgs.dev-manager-desktop dotfilesPkgs.railway ];

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
```

```nix
# hosts/nixos-desktop/configuration.nix
{ pkgs, ... }: {
  dotfiles = {
    bootloader.enable = true;
    display-manager.enable = true;
    misc.enable = true;
    zsh-shell.enable = true;
    nix-ld.enable = true;
    timezone.enable = true;
    pipewire.enable = true;
    gaming.enable = true;
    hyprland.enable = true;
    networking.enable = true;
    # ollama.enable = true;  # still disabled
  };

  nix = {
    optimise.automatic = true;
    settings.experimental-features = ["nix-command" "flakes" "impure-derivations" "ca-derivations"];
    gc.automatic = true;
    gc.options = "--delete-older-than 30d";
  };

  swapDevices = [ { device = "/swapfile"; size = 16 * 1024; } ];
  services.xserver = { enable = true; xkb = { layout = "us"; variant = ""; }; videoDrivers = ["modesetting"]; };
  users.users.fveracoechea = { isNormalUser = true; description = "fveracoechea"; extraGroups = ["networkmanager" "wheel" "audio" "docker" "dialout" "plugdev"]; };
  virtualisation.docker.enable = true;
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [ vim wget git curl zip unzip cmake gnumake cargo openssl lazydocker ];

  system.stateVersion = "24.05";
}
```

## External consumer contract

A foreign flake consuming this one:

```nix
{
  inputs.dotfiles.url = "github:fveracoechea/dotfiles";
  inputs.neovim-config.url = "github:fveracoechea/neovim-nix-config";  # only if enabling dotfiles.neovim
  # ...
  outputs = { self, nixpkgs, home-manager, dotfiles, neovim-config, ... }: {
    homeConfigurations."me@other-laptop" = home-manager.lib.homeManagerConfiguration rec {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = {
        dotfilesPkgs = dotfiles.dotfilesPkgs.x86_64-linux;
        inputs.neovim-config = neovim-config;  # only if enabling dotfiles.neovim
      };
      modules = [
        dotfiles.homeManagerModules.default  # aggregate — brings the whole dotfiles.* tree
        {
          dotfiles = {
            shell.enable = true;
            neovim.enable = true;  # requires neovim-config input above
            # gaming not enabled on this laptop
          };
        }
      ];
    };
  };
}
```

**Consumer contract summary:**
- `dotfilesPkgs` (required) — `dotfiles.dotfilesPkgs.${system}`.
- `inputs.neovim-config` (only if `dotfiles.neovim.enable = true`) — the external Neovim config flake. Disappears when Neovim is in-housed.

## Concrete refactor tasks (suggested ordering)

1. **Create `modules/core/`** with `palette.nix` (hardcoded catppuccin-mocha attrset as the `dotfiles.palette` default) and `monitors.nix` (empty-list default `dotfiles.monitors`).
2. **Extend `packages/default.nix`** to take `{ pkgs, inputs, system }` and wrap `hyprland`, `hyprland-portal`, `tmux-powerkit` from inputs alongside the locally-built packages.
3. **Rewrite `flake.nix`** to the target shape: export `homeManagerModules`/`nixosModules`/`darwinModules` (per-name + `.default` aggregate), export `dotfilesPkgs` per-system, drop `customUtils`/`system` from `specialArgs` (keep `dotfilesPkgs` + `inputs`), keep `neovim-config` input.
4. **Create the three aggregate files**: `modules/home-manager/default.nix`, `modules/nixos/default.nix`, `modules/darwin/default.nix` — each a hand-maintained `imports = [...]` of core + per-name modules in that layer.
5. **Convert each existing module** to the `dotfiles.<name>.enable` pattern: wrap body in `mkIf`, declare `options.dotfiles.<name>.enable`, replace `customUtils.catppuccin` → `config.dotfiles.palette`, replace `customUtils.monitors` → `config.dotfiles.monitors`, replace `inputs.<x>.packages.${system}` → `dotfilesPkgs.<x>`. Rename `displayManager.nix` → `display-manager.nix`, `miscellaneous.nix` → `misc.nix`. Hyprland's 11 Nix sub-files stay as-is — just wrap the `default.nix` body in `mkIf config.dotfiles.hyprland.enable`.
6. **Extract lazygit** from `git.nix` into its own `modules/home-manager/lazygit.nix`; create `modules/home-manager/lazydocker.nix`.
7. **Create `modules/home-manager/shell.nix`** grouping (imports the 9 members, cascades via `mkDefault`).
8. **Create `modules/home-manager/neovim.nix`** — thin wrapper that imports `inputs.neovim-config.homeManagerModules.default` and exposes `dotfiles.neovim.enable` (wraps in `mkIf`). This keeps the host's `dotfiles.*.enable` surface uniform without in-housing the lua config.
9. **Rewrite hosts**: `hosts/nixos-desktop/{configuration,home}.nix` and `hosts/macbook-pro/{configuration,home}.nix` — replace `imports = [...]` with `dotfiles.*.enable` switches; move monitor specs into `dotfiles.monitors`; keep host-specific packages as raw `home.packages`; remove the `inputs.neovim-config.homeManagerModules.default` import (now handled by the wrapper + `dotfiles.neovim.enable`).
10. **Delete `utils/`** directory entirely.
11. **Update `README.md`** repository structure section + the "Highly Customizable" / "Modular configuration" bullet to reflect the new `dotfiles.*.enable` model.
12. **Verify**: `nix flake check`, then `nixos-rebuild test --flake .#nixos-desktop` and `darwin-rebuild check --flake .#macbook-pro` (the USER runs these, not the agent — per AGENTS.md).

## ADRs to write

One new ADR is warranted for this refactor — it meets all three criteria (hard to reverse, surprising without context, result of real trade-offs):

- **`docs/adr/0004-dotfiles-enable-namespace.md`** — Document the shift from `imports = [...]` to `dotfiles.*.enable`, the single-namespace mixed-granularity choice, the `mkDefault` cascade for groupings, the two-tier package policy (no `dotfiles.dev`), and the decision NOT to bridge NixOS↔HM eval contexts. Reference the rejected alternatives (two namespaces `configurations.*`+`bundles.*`; auto-enable; full per-app theming options).

The other existing ADRs remain valid and UNCHANGED in this refactor:
- `0001-thin-hosts-with-focused-modules.md` — still true; hosts are still thin, just flip switches instead of import paths.
- `0002-per-application-manual-theming.md` — still true; NO theming work in this refactor. The palette moves from `customUtils.catppuccin` to `config.dotfiles.palette` (a mechanical relocation, not a theming change). Multi-theme support remains deferred. Do NOT touch this ADR.
- `0003-homebrew-and-home-manager-split-on-macos.md` — unaffected.

## Deferred work (NOT in scope for this refactor)

The following were discussed during planning and explicitly deferred. The directory structure and module contracts in this handoff accommodate them so they can land later as additive changes:

1. **Hyprland → lua migration.** Hyprland 0.55 (pinned) deprecated hyprlang in favor of lua. Currently the config is 11 Nix sub-files pushing into `programs.hyprland.settings`. Deferred work: rewrite `modules/home-manager/hyprland/default.nix` to write `hyprland.lua` + a `lua/` sub-tree to `~/.config/hypr/` via `home.file`, replacing the Nix sub-files. Reference: https://wiki.hypr.land/Configuring/Start/ ; migration tool: `hyprconf2lua` (https://github.com/Prateek-squadron/hyprconf2lua). The co-location convention (Q6: multi-file source under `lua/` subdir) is already documented to receive this.

2. **Neovim in-housing.** Currently Neovim config comes from the external `github:fveracoechea/neovim-nix-config` flake, wrapped by `modules/home-manager/neovim.nix`. Deferred work: fetch that flake's lua source, port it into `modules/home-manager/neovim/lua/`, rewrite `neovim.nix` → `neovim/default.nix` to wire the lua tree via `home.file`, remove the `neovim-config` flake input, and drop `inputs` from `specialArgs` (the neovim wrapper was the only reason `inputs` survived in `specialArgs`). 

3. **Multi-theme support.** Currently `config.dotfiles.palette` is a hardcoded catppuccin-mocha attrset. Deferred work: add a `themes/` dir (one file per theme), a `config.dotfiles.theme.name` selector, a canonical palette schema (26 keys), and possibly style tokens (radius, font). ADR 0002 stays valid until this lands; at that point it gets superseded by a new theming ADR. See the grilling session's Question 11 for the full design sketch (canonical schema + palette/radius/font tokens).

## Glossary updates already made

The following terms in `CONTEXT.md` have ALREADY been updated during the grilling session (the implementing agent should NOT re-update them, just verify they're consistent):

- **Custom Utils** — marked as legacy; replaced by `config.dotfiles.palette` + `config.dotfiles.monitors`.
- **Custom Pkgs** — marked as legacy; replaced by `dotfilesPkgs`.
- **Dotfiles Pkgs** — NEW term; the `specialArgs`-injected package set (locally-built + wrapped-from-inputs).
- **Dotfiles Option** — NEW term; the `dotfiles.<name>.enable` boolean switch.
- **Grouping** — NEW term; a `dotfiles.*` module that composes atomics via `mkDefault` cascade.

Terms NOT yet added (implementer may want to add if they come up):
- A term for the aggregate `default.nix` files (probably not needed — it's an implementation detail, not a domain concept).

## Suggested skills for the implementing agent

- **tdd** — if you want to write NixOS tests for the module contract (optional; Nix testing is heavy).
- **diagnose** — if `nix flake check` or `nixos-rebuild test` surfaces eval errors during the conversion (likely, given the scope).
- **to-issues** — if you want to break this refactor into tracked GitHub issues (the task list above maps cleanly to issues).

## Key references

- nix-darwin module docs: https://github.com/LnL7/nix-darwin
- Home Manager module docs: https://github.com/nix-community/home-manager
- External Neovim config (wrapped, not in-housed in this refactor): https://github.com/fveracoechea/neovim-nix-config
- Hyprland lua config (for deferred migration): https://wiki.hypr.land/Configuring/Start/
- `hyprconf2lua` migration tool (for deferred migration): https://github.com/Prateek-squadron/hyprconf2lua
