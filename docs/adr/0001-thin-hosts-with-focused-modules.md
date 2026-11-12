# ADR-0001: Keep hosts thin with capability-owned modules

## Status

Accepted. Amended 2026-11-08: reusable implementations belong to capabilities; host-only services remain host-owned rather than using the reusable module interface. Amended 2026-11-12: shared capabilities may own an optional managed execution mode using their common policy and assets.

## Context

Host configuration mixed machine facts with reusable application policy.
Organizing reusable implementations by evaluation context also separated related package and integration decisions.
Host-only services had no cross-host reuse need and benefited from keeping their application and infrastructure settings together.

## Decision

Host configurations select reusable modules and supply machine-specific settings.
Reusable configuration belongs to capability-owned modules, including their package selection, integrations, native assets, and checks.
Explicit, static context registries expose those capabilities without owning their implementations.

Home Manager modules configure the user environment, while System Modules configure NixOS.
Only configuration with an actual cross-host reuse need belongs in a reusable module.
An existing shared capability may also own an optional managed execution mode when both modes consume its common policy and assets.
This keeps that policy together even when only one host selects the managed mode.
Host identity, endpoint routing, access decisions, and deployment composition remain host-owned.
Host-only services stay with their host and keep application, reverse-proxy, firewall, and secret-reference settings together.
Services outside that shared-capability execution mode use direct imports without a separate enable-switch interface.
To understand a host, read its selected reusable modules and host-owned services.

## Consequences

Home and System remain separate evaluation contexts, even when one capability owns configuration in both.
Capability ownership keeps integration knowledge out of hosts, at the cost of maintaining explicit context registration.
An optional managed mode adds a capability interface before a second host needs it, but avoids duplicating policy between execution modes.

## Alternatives considered

Organizing implementations by evaluation context separates related capability policy and makes hosts assemble its parts.
Automatic module discovery hides registration and is not used.
Keeping a shared capability's managed execution mode entirely host-owned would split its policy and assets between owners.

Related: ADR-0005 (native assets follow capability ownership).
