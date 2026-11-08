# Thin hosts with focused modules

## Status

Accepted. Amended 2026-11-08: host-only services remain host-owned rather than using the reusable module API.

## Decision

Host configurations select reusable modules and supply machine-specific settings.
Reusable configuration lives in focused modules under `modules/{nixos,home-manager}/`.

Home Manager modules configure the user environment, while System Modules configure NixOS.
Only configuration with an actual cross-host reuse need belongs in a reusable module.
Host-only services stay with their host and keep application, reverse-proxy, firewall, and secret-reference settings together.
They use direct imports without a separate enable-switch API.
To understand a host, read its selected reusable modules and host-owned services.
