# ADR-0008: Preserve server software during repository consolidation

## Status

Accepted - 2026-11-08. Decided in #50.

## Context

The desktop and servers used separate repositories and dependency graphs.
Several deployed server services were newer than the desktop's Release Channel equivalents.
Changing those dependencies during consolidation could downgrade services or alter persistent data.
Shared modules had also changed since the servers last deployed them.

## Decision

Consolidate host ownership while retaining the servers' complete, immutable dependency graph.
Preserve compatibility-sensitive shared module behavior as well as System packages because package versions alone do not prove equivalence.
Keep hardware, networking, secrets, and authorization host-specific.
New reusable capabilities use the existing Dotfiles Option namespace and upstream configuration options.

This temporarily departs from ADR-0007 for the servers.
Remove the compatibility sources only through a separately reviewed Release Channel migration that passes software, compatibility, and data-recovery checks.
The desktop's channel policy remains unchanged.

## Consequences

- Personal-tool updates do not change server software.
- Old shared behavior remains an explicit maintenance cost until the server migration.
- Evaluation can establish configuration equivalence but cannot establish backup quality or safe activation.

## Alternatives considered

- Move servers to the desktop's Release Channel immediately. Rejected because it would downgrade deployed services.
- Retain selected service packages within a newer System module tree. Rejected because module and runtime changes could still break compatibility.
- Wait for a later release before consolidation. Rejected because repository ownership can change independently of deployed software.

Related: ADR-0007 (package ownership still governs the desktop and the eventual server Release Channel migration).
