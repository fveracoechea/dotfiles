# Server consolidation and deployment

The dotfiles flake owns `nixos-desktop`, `homelab`, and `vps`.
Consolidation does not upgrade server System software or move service data.
Homelab's Home uses current Home Manager and Latest Channel tools independently of its System.
The temporary server dependency policy is recorded in [ADR-0008](adr/0008-preserve-server-software-during-consolidation.md).

## Host ownership

Each host imports its services directly from `hosts/<host>/services/`.
Each service file owns its application settings, proxy virtual host, firewall exposure, and secret references.
Caddy's own file owns certificates, redirects, and proxy-wide settings.
Host-only services have no `dotfiles.*.enable` wrappers and are not exported as reusable modules.
`modules/` contains only reusable configuration, selected through `dotfiles.*.enable` switches.
Host directories also retain hardware, storage, networking, and authorization settings.
Neither server imports desktop defaults.

The desktop retains its existing channels, hostname `nixos`, packages, and enabled capabilities.
Homelab retains Home Manager.
The VPS has no Home Manager configuration.
The public `homeManagerModules.default`, `nixosModules.default`, and `dotfilesPkgs` exports remain available.
Custom Package definitions remain in their existing package sources; none were copied into host directories.

## Preserved sources

These sources are immutable in `flake.nix`, not just incidentally locked to moving branches.

| Input | Revision | Consumers | Removal condition |
| --- | --- | --- | --- |
| `nixpkgs-servers` | `2fcb964de67fcf60b43471c55d5d99e61a9ccb5a` | Both server System module trees and packages, plus homelab's System-coupled Home Zsh | Reviewed server Release Channel migration |
| `server-disko` | `ff8702b4de27f72b4c78573dfb89ec74e36abdf1` | VPS storage module | Storage and boot equivalence validated with replacement module |
| `server-dotfiles-compat` | `a4ede6eddbb6f3bc3b8c98cff0d86c99661f0f46` | Homelab System shell, timezone, and System Dotfiles Pkgs | Shared System behavior validated against current modules |

The compatibility source retains its transitive inputs, including its own historical Home Manager dependency.
Homelab no longer imports that Home aggregate or a separate frozen Home Manager integration.
Its Home shares the desktop's current modules and Latest Channel package set.
Home Zsh and tmux match the preserved System's registered login shell.
Do not deduplicate the remaining System compatibility sources by following the desktop inputs.

The servers report `26.11.20260810.2fcb964`.
This identifies a development snapshot, not the released NixOS 26.11.
A later Release Channel migration is a separate change after release and compatibility review.
Do not schedule an automatic channel switch.

## Verified baseline

The baseline was refreshed over SSH on 2026-11-08 without building or activating a System.
Both active System paths matched evaluation of the original homelab repository at `4901bf69ae42c85789c0b7452100054d9a6b4ed3`.
The source repository's uncommitted documentation and agent changes were left untouched.

[`checks/server-baseline.json`](../checks/server-baseline.json) records the active generations, service versions, running runtime executables, database extensions, and container identity.
The service versions come from the evaluated graph that matches those active generations.
Running unit commands and selected `/proc/<pid>/exe` paths were checked separately.
All inspected application and control-plane units were active.
The live Immich database reports pgvector `0.8.6` and VectorChord `1.1.1`.
PostgreSQL remains on major 17 explicitly.

Paperless-gpt's running registry digest is:

```text
ghcr.io/icereed/paperless-gpt@sha256:6b9024d1adebfcd6bd7ec5e9da2ca17f9879b1fb5ce749d72905bbb121091ef8
```

Its image configuration ID is recorded separately.
The application version was not identifiable from the container labels, so preservation depends on the exact registry digest.
The image was not resolved again from `latest`.

The historical VPS comparison reproduced its deployed System path when its previous hostname, `hostinger`, was restored.
Its real selector, host directory, and configured hostname are now `vps`.
The baseline retains the historical hostname and System path; they are deployment evidence, not current configuration names.
The Headscale DERP region code and display name remain unchanged to preserve the existing control-plane configuration.
The historical homelab comparison reproduced its deployed System path when the old image reference was restored.
The real host configuration uses the verified digest instead.
Those comparisons preceded the coding-agent addition and are not current check results.
It does not prove current data or backup integrity.

## Evaluation gates

These commands do not build or activate Systems:

```sh
nix flake check --no-build
nix eval --raw .#nixosConfigurations.nixos-desktop.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.vps.config.system.build.toplevel.drvPath
```

The owner selected basic Nix configuration evaluation as acceptance for this refactor.
Capability checks evaluate selected actual Host settings without runtime fixtures or mutation cases.
The heavyweight preservation gate and its diagnostic exports are removed.
The historical baseline and immutable input revisions remain unchanged.
Evaluation does not prove runtime behavior, deployed identity, authentication, or safe activation.

The desktop System derivation before and after the initial import was identical:

```text
/nix/store/7f73an60kzv2rcixmh8l2s7jh1n1ia3c-nixos-system-nixos-26.05.20261105.c56a87d.drv
```

The subsequent host rename changes the desktop's generated SSH alias from `hostinger` to `vps`.
Its System derivation therefore changes through Home Manager; its channels and enabled capabilities remain unchanged.

## User-only operational acceptance

Build, recovery, activation, and reboot acceptance remain owner tasks.
Do not treat `nixos-rebuild test` as a read-only check.
It starts services and can trigger persistent database migrations.
A generation rollback does not restore migrated data.

Before any activation:

1. Confirm independent SSH or provider-console access to the VPS without relying on the VPN being changed.
2. Verify recoverable backups and test restores with matching software on copies.
3. Include PostgreSQL roles and the Immich, Paperless, and Vaultwarden databases.
4. Include Immich media, Paperless data and media, Vaultwarden attachments, Home Assistant state, Z-Wave state and keys, Headscale and Headplane state, and paperless-gpt volumes.
5. Confirm actual data paths and host-local secret references from the evaluated configuration and running services.
6. Retain the active generations and required container image through garbage collection.
7. Recheck the active System paths and running image digest against the baseline.
8. Run the evaluation gates above, then the full `nix flake check`.
9. Build each candidate System as the owner before the maintenance window.

The existing host-local references remain unchanged:

| Host | Reference | Use |
| --- | --- | --- |
| Both servers | `/var/lib/caddy/caddy.env` | Cloudflare DNS-01 credentials |
| Both servers | `/var/lib/tailscale/auth-key` | Tailnet authentication |
| Homelab | `/var/lib/paperless/admin-password` | Initial Paperless administrator password |
| Homelab | `/var/lib/vaultwarden/vaultwarden.env` | Vaultwarden secrets |
| Homelab | `/var/lib/paperless-gpt/paperless-gpt.env` | Paperless API token |
| Homelab | `/var/lib/zwave-js/secrets.json` | Z-Wave security keys |
| VPS | `/var/lib/headplane/cookie-secret` | Headplane session secret |

Do not replace these files or copy their contents into the repository.
Certificate paths remain under `/var/lib/acme/veracoechea.com/` on homelab and `/var/lib/acme/vpn.veracoechea.com/` on the VPS.
Keep all authorization rules host-specific.

After those preparations and activation of the desktop's renamed SSH alias, deploy from this checkout:

```sh
# Owner only, during the maintenance window. These commands activate services.
just deploy-vps
just deploy-homelab
```

Each deployment recipe runs `just evaluate` before `nixos-rebuild switch`, without a confirmation prompt.
This evaluates the flake without building Systems; it does not compare historical whole-Host identities.
It does not verify backups or replace owner-run build and smoke tests.
Before the desktop SSH configuration is activated, use `just deploy-vps hostinger` with the legacy SSH alias.
Renaming the selector does not itself install the new SSH alias or change the running server's hostname.

Validate the VPS first through independent access.
Check Headscale, Headplane login and tailnet-only restrictions, existing peers, DERP, Tailscale, Caddy, SSH, and Fail2ban.
Then check homelab LAN DNS, TLS, subnet routing, photo upload and search, document import and OCR, Vaultwarden sync, home automation, radios, and GPU inference.
Reboot each server and repeat the checks needed to confirm boot-time operation.

## Retire the previous deployment workflow

The previous `~/Code/homelab/justfile` activates services from the old flake.
Do not use it for new configuration changes.
Keep the old repository and its uncommitted work until operational acceptance is complete.

After the owner accepts both deployments, remove or disable those old deployment recipes and mark that repository read-only for configuration ownership.
Update any external automation to run from this dotfiles checkout using `homelab` and `vps` selectors.
Record the accepted deployed manifests and generation paths here.
Do not delete the old repository as part of retirement.

## Remove the temporary compatibility sources

Review a released server Release Channel candidate separately.
Compare actual configured packages, database majors, runtimes, extensions, container identity, and module behavior against a freshly verified deployed baseline.
An equal or newer version is necessary for that migration but does not establish data compatibility.
Do not mix individually retained server packages into a newer System module tree.
Retain the old source if a candidate requires a downgrade or lacks a safe recovery procedure.
Basic configuration evaluation does not replace the operational acceptance required for that migration.
