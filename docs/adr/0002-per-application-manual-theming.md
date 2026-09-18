# Per-Application Manual Theming

Themes are configured per application rather than through a unified theming framework like Stylix.
A shared `config.dotfiles.palette` attribute set supplies the colors, and each application's configuration applies them.

This decision favors per-application control over a framework's shared configuration.
The accepted cost is maintaining each application's color conversion and assignments.
A different palette can use those assignments, but multi-theme support remains deferred.

## Historical and current ownership

The original implementation used `customUtils.catppuccin`.
[ADR-0004](0004-dotfiles-enable-namespace.md) replaced it with `config.dotfiles.palette`; the per-application Theme decision did not change.

The native Hyprland migration passes raw `blue`, `flamingo`, and `surface2` values through a Nix-generated JSON bridge.
Hand-written Lua converts and applies those colors; Nix does not generate compositor settings.
Hyprlock still applies the palette through its Home Manager Module.
See the [Hyprland guide](../hyprland-summary.md#bridge-and-lifecycle) for the current bridge and ownership.
