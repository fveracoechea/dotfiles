# Dotfiles

This repository defines the personal Linux environment for a desktop, homelab, and VPS.
It also provides reusable configuration and packages for other Linux hosts.

## Language

**Host**:
A physical or virtual machine whose System and optional Home configuration belong to this repository.

**Custom Package**:
A package defined by this repository rather than supplied by an upstream package source.
_Avoid_: local package, in-repo package

**Dotfiles Pkgs**:
The repository-provided package collection containing Custom Packages and packages supplied by upstream inputs.
_Avoid_: customPkgs, Custom Pkgs

**Release Channel**:
The released NixOS package source designated for System-owned packages by default.
_Avoid_: stable, stable channel, stable nixpkgs

**Latest Channel**:
The rolling package source designated for Home-owned applications and personal tools by default.
_Avoid_: unstable, unstable channel, bleeding edge

**Version-Coupled Package**:
A package whose compatibility depends on a partner owned by the other configuration layer.
It shares its partner's channel rather than its owner's default channel.
_Avoid_: pinned package, exception, override

**Channel Hold**:
A temporary Release Channel assignment for a Home-owned package that does not build or work on the Latest Channel.
_Avoid_: pin, workaround, exception

**System Toolset**:
The minimal set of packages needed for boot, System administration, recovery, or a System Module.
_Avoid_: system packages, global tools

**System**:
The Host's OS-level configuration layer, including hardware, boot, networking, and services.

**Home**:
The Host's user-level configuration layer, including personal applications, shell configuration, and themes.

**Home Manager Module**:
A reusable unit of Home configuration for one capability or Grouping.

**System Module**:
A reusable unit of System configuration for one capability or Grouping.

**Dotfiles Option**:
A project-owned opt-in switch for a reusable capability or Grouping.
_Avoid_: bundle, profile

**Grouping**:
A set of reusable capabilities selected through one Dotfiles Option, with individually optional members.
_Avoid_: bundle, profile, suite

**Config Directory**:
The repository-owned collection of native application configuration, organized by application.
_Avoid_: config folder, dotfiles directory

**Steam Session**:
The desktop's dedicated fullscreen Steam session for game streaming through the Dummy Plug.
_Avoid_: gamescope session, big picture session

**Dummy Plug**:
The desktop's physical display emulator that provides a display output for headless game streaming.
_Avoid_: virtual display, fake monitor, headless dongle
