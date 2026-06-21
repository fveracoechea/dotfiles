# dotfiles.* Enable Namespace

All module activation switched from `imports = [ ./path/to/module.nix ]` in host configs to `dotfiles.<name>.enable = true;` boolean switches under a single flat `dotfiles.*` namespace. Each module declares `options.dotfiles.<name>.enable` and wraps its body in `lib.mkIf config.dotfiles.<name>.enable { ... }`.

The namespace is mixed-granularity: some entries are single apps (`dotfiles.git`, `dotfiles.ghostty`, `dotfiles.fuzzel`), some are groupings (`dotfiles.shell` = zsh + tmux + oh-my-posh + bat + btop + yazi + git + lazygit + lazydocker; `dotfiles.gaming` = steam + gamescope). Groupings cascade to their members via `lib.mkDefault`, so a host can opt out of any member by setting it to `false` explicitly. Groupings and atomics are distinguished by name only — no marker.

## Trade-offs

This trade-off favors discoverability and uniform host API over the minimal-machinery of raw imports. A host config reads as a list of switches (`dotfiles.git.enable = true;`), not a list of file paths. The cost is per-module option boilerplate and the `mkIf` wrapper.

## Rejected alternatives

- **Two namespaces (`configurations.*` for apps + `bundles.*` for groupings)** — rejected as unnecessary ceremony; one namespace with mixed granularity is simpler and the grouping/atomic distinction is clear from names.
- **Auto-enable (grouping sets member `.enable = true` without mkDefault)** — rejected because it breaks opt-out: a host wanting the shell suite minus one app would hit a duplicate-definition error. `mkDefault` yields to explicit host values.
- **Full per-app theming options (`dotfiles.git.userName`, `dotfiles.git.email`)** — rejected as the classic wrapper-repo anti-pattern; hosts override via the upstream HM/nixpkgs option directly (HM merges), so re-exposing upstream options under a custom namespace is noise.
- **Bridging NixOS↔Home Manager eval contexts (one switch fires both layers)** — rejected to keep things clean; apps spanning both layers (hyprland, gaming, zsh) get two switches with the same name in separate eval contexts. Prerequisites are documented in `mkEnableOption` descriptions, not enforced via cross-context assertions (which don't work).
- **Shared accumulator options (`dotfiles.unfreePackages`)** — rejected; nixpkgs merges `nixpkgs.config.permittedInsecurePackages` across modules, so a custom accumulator reinvents upstream merging.

## Package plumbing

`customUtils` (palette + monitors catalog) is replaced by `config.dotfiles.palette` (hardcoded catppuccin-mocha attrset, multi-theme support deferred) and `config.dotfiles.monitors` (host-declared list of monitor spec strings). `customPkgs` is renamed to `dotfilesPkgs` and extended to wrap non-nixpkgs flake inputs (hyprland, tmux-powerkit) so modules never touch `inputs` or `system` directly for packages. No overlays.

## Flake exports

The flake exports `homeManagerModules`, `nixosModules`, `darwinModules` — each an attrset with per-name entries (`homeManagerModules.git`, `homeManagerModules.shell`, etc.) plus a `.default` aggregate that imports every per-name module in that layer. External consumers can import `.default` for the full suite or pick per-name modules.
