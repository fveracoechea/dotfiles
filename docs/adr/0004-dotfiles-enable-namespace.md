# dotfiles.* Enable Namespace

All module activation switched from `imports = [ ./path/to/module.nix ]` in host configs to `dotfiles.<name>.enable = true;` boolean switches under a single flat `dotfiles.*` namespace. Each module declares `options.dotfiles.<name>.enable` and wraps its body in `lib.mkIf config.dotfiles.<name>.enable { ... }`.

The namespace includes single apps such as `dotfiles.git` and groupings such as `dotfiles.shell`.
Groupings cascade to their members via `lib.mkDefault`, so a host can opt out of any member by setting it to `false` explicitly.
Names distinguish groupings from atomics without a separate marker.

## Trade-offs

This trade-off favors discoverability and uniform host API over the minimal-machinery of raw imports. A host config reads as a list of switches (`dotfiles.git.enable = true;`), not a list of file paths. The cost is per-module option boilerplate and the `mkIf` wrapper.

## Rejected alternatives

- Separate `configurations.*` and `bundles.*` namespaces add names without changing how the modules work.
  One namespace supports both apps and groupings.
- Auto-enabling a member without `mkDefault` prevents a host from opting out.
  `mkDefault` yields to explicit host values.
- Per-app options such as `dotfiles.git.userName` duplicate upstream Home Manager options.
  Hosts set the upstream option directly.
- A single switch cannot activate both NixOS and Home Manager evaluation contexts.
  Apps spanning both layers use two switches with the same name.
  `mkEnableOption` descriptions record prerequisites.
- A custom accumulator such as `dotfiles.unfreePackages` duplicates nixpkgs option merging.

## Package plumbing

The namespace refactor replaced `customUtils`, which held the palette and monitor catalog, with `config.dotfiles.palette` and a host monitor option. The later Lua migration moved this desktop's monitor declarations into native Lua.
The palette is a fixed Catppuccin Mocha attribute set, with multi-theme support deferred.
The monitor option is a host-declared list of spec strings.
The native Hyprland migration keeps those inputs in Nix and sends them through the [JSON bridge](../hyprland-summary.md#bridge-and-lifecycle); compositor settings remain hand-written Lua.
The earlier upstream-option override guidance does not authorize adding generated Hyprland settings.

The refactor also renamed `customPkgs` to `dotfilesPkgs` and wrapped non-nixpkgs inputs so package consumers did not need direct access to `inputs` or `system`.
The original Hyprland input wrapper is historical.
[ADR-0007](0007-split-nixpkgs-channels-by-package-owner.md) moved the compositor to the System's Release Channel package and removed that input.
Current input wrappers in `packages/default.nix` include `herdr` and `tmux-powerkit`.
No overlays are used for this package wiring.

## Flake exports

The flake exports `homeManagerModules.default` and `nixosModules.default`.
Each aggregate imports all modules in its layer.
External Linux consumers import the aggregate and select modules with `dotfiles.<name>.enable`.
