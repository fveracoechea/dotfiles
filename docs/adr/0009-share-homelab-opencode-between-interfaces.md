# ADR-0009: Share homelab OpenCode between interfaces

## Status

Accepted - 2026-11-13. Requested by the owner during homelab sign-in troubleshooting.

## Context

The owner's terminal sessions and OpenAI login belonged to their personal OpenCode service.
The web interface used an isolated service identity with separate sessions and credentials.
Browser authentication succeeded, but it did not give that service access to the owner's model-provider connection.
The owner wanted both interfaces to share existing sessions and provider accounts without copying credentials between databases.

## Decision

The homelab's terminal and web interfaces use the owner's personal OpenCode service because its database already owns the required sessions and credentials.
The service remains authenticated and reachable through the existing tailnet-only HTTPS route.
It starts independently of interactive logins.
This replaces the dedicated web identity for the homelab, not the access policy for other services.

## Consequences

- A browser session has the same filesystem, project, and privilege access as the owner's terminal agent, including passwordless sudo authority.
- Provider sign-ins and session changes are visible through both interfaces without credential synchronization.
- The retired web service's state remains separate and is not merged or deleted.

## Alternatives considered

- Keep isolated identities and sign in twice. Rejected because sessions would still remain separate.
- Copy credentials between services. Rejected because copies would drift and would not unify sessions.

Related: ADR-0008 (host-specific access and service-identity decisions remain owner-controlled).
