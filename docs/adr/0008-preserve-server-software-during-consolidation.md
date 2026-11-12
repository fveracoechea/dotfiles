# ADR-0008: Preserve server software during repository consolidation

## Status

Accepted - 2026-11-08. Decided in #50. Amended 2026-11-09: permit current coding agents in homelab's managed Home, with exact unrelated behavior preservation. Amended 2026-11-12: accept basic configuration evaluation without whole-System or mutation test gates.

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

Homelab's requested coding-agent addition, including its explicitly requested authenticated web endpoint, is the permitted functional change during the capability refactor.
It remains in the NixOS-integrated Home and uses current personal-tool dependencies without replacing the server dependency graph.
A temporary capability-owned adapter shares current policy while retaining the older Home Manager contract.
Remove that adapter when the separately reviewed server migration supplies the current contract.

The addition necessarily changes homelab's complete System identity because that identity includes Home.
Retain the historical whole-System and Home change records without requiring counterfactual or mutation checks for this refactor.
Keep unrelated System and Home behavior unchanged; basic configuration evaluation does not prove that preservation.
Any web exposure requires an owner-approved access and service-identity model and a separately enumerated service and proxy allowance.
Keep immutable input revisions and unrelated VPS behavior unchanged.

This temporarily departs from ADR-0007 for the servers.
Remove the compatibility sources only through a separately reviewed Release Channel migration that passes software, compatibility, and data-recovery checks.
The desktop's channel policy remains unchanged.

## Consequences

- Personal-tool updates do not change server software.
- Old shared behavior remains an explicit maintenance cost until the server migration.
- Evaluation can establish configuration equivalence but cannot establish backup quality or safe activation.
- Shared permissive agent policy does not authorize privileged server operations; owner review and runtime acceptance precede activation.

## Alternatives considered

- Move servers to the desktop's Release Channel immediately. Rejected because it would downgrade deployed services.
- Retain selected service packages within a newer System module tree. Rejected because module and runtime changes could still break compatibility.
- Wait for a later release before consolidation. Rejected because repository ownership can change independently of deployed software.

Related: ADR-0007 (package ownership still governs the desktop and the eventual server Release Channel migration).
