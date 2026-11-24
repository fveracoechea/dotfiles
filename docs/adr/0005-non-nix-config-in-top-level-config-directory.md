# ADR-0005: Keep native configuration with its capability owner

## Status

Accepted. Amended 2026-11-08: repository-owned native assets belong to their capability; externally owned sources remain external.
Amended 2026-11-23: managed Neovim installations archive retired plugin state instead of treating runtime-only additions as user edits.

## Context

Native application configuration needed editor support and native formatters without Nix string escaping.
Separating native assets from their capability implementation spread maintenance across unrelated locations.
Some configuration and skills had external owners and consumers outside this repository.

## Decision

Repository-owned native configuration belongs beside the capability that installs it, in its native format.
Small generated data may remain generated rather than becoming hand-authored native files.
External ownership takes precedence over physical colocation.
Operator owns its instructions, upstream projects own their skills, and the shared Neovim repository owns its Lua source and plugin lockfile.
Consumers reference those sources rather than maintaining copies.

Neovim supports Nix and non-Nix installation from the same source.
Its plugin lockfile remains writable because its plugin manager writes it directly.
Normal installations advance the lockfile with the selected configuration revision and reject edits to existing plugin pins.
Retired plugin state and additive runtime bookkeeping are archived because Neovim otherwise restores obsolete entries on startup.
Genuine conflicts are checked before Home changes its managed files.
Plugin updates belong to the shared repository; development installations may link its writable lockfile explicitly.
Runtime state stays separate from shared source.

## Consequences

Native edits reach applications through the next rebuild, together with package and plugin changes.
Capability migration may move repository-owned assets, but does not transfer ownership of external instructions, skills, or editor configuration.
Retired plugin archives consume space until the owner removes them.
Existing application-oriented placement can remain until its capability migrates.

## Alternatives considered

One central native configuration collection makes native files easy to browse but separates capability changes from their installation policy.
Embedding non-trivial native source in Nix loses native editor support and adds string escaping.
Deleting retired plugin state can lose local plugin work, while rejecting all runtime bookkeeping makes ordinary upgrades fail repeatedly.

Related: ADR-0001 (capabilities own reusable implementations).
