# Homelab coding agents

Homelab uses the current coding-agent capability in its existing NixOS-integrated Home.
Its Home uses the same current Home Manager, shared modules, and Latest Channel packages as the desktop.
Only its System dependencies remain frozen under ADR-0008.
Unrelated desktop behavior must remain unchanged.
The recovered content includes main's native supervisor/worker modes and OpenAI compaction policy, with a 25% buffer and 20000 kept tokens.
Operator and its coupled agent prompts use the authorized stable v2.3.2 release.
Herdr notification sound is disabled without changing its visual notification policy.
These ordinary content edits do not resolve the root PR's separate Git ancestry conflict or establish default-branch readiness before landing.

## Dependency wiring

`flake.nix` imports `modules/coding-agents/composition.nix` with `inputs` and `stablePkgsFor`.
That call returns a Home Manager module; Home Manager supplies its second argument, including the Home's `pkgs`.
The module's `_module.args` supplies named dependencies to the shared coding-agent modules:

- `codingAgentPkgs` selects ordinary tool packages from the Home's package set.
- `codingAgentSources` supplies locked source trees for integrations, skills, and agent prompts.
- `codingAgentPackages` supplies repository-defined packages, including Operator and Herdr integration.
- `codingAgentMcpPackage` selects `mcp-nixos` from the Release Channel under the Channel Hold documented in `opencode.nix`.

This module installs nothing by itself; the capability's enabled Home modules consume these dependencies.
Both hosts supply their Latest Channel Home package set through this composition module.

## Shared Home configuration

`modules/coding-agents/home.nix` is the Home entry point for both homelab and desktop.
Current Home Manager generates OpenCode instructions, skills, and CLI settings directly.
Its `validateFiles` options validate both OpenCode configuration files against the selected executable's schemas.
No frozen Home adapter or package-list filtering is required.

Homelab imports the current Home aggregate instead of the historical compatibility Home.
This also updates its enabled shell tools, Neovim, and fonts to the shared modules and Latest Channel packages.
Home Zsh and tmux still use the preserved System's Zsh package so they match the registered login shell.
Home Manager's release check is disabled for the intentional Home/System channel split, as on desktop.

The current Git module no longer installs Hunk or GitHub CLI.
The coding-agent capability owns those packages and their Hunk configuration, including Git/lazygit pager integration.
The capability check evaluates both hosts' OpenCode package, settings, CLI preferences, validation options, and Herdr settings, plus homelab's shared service and proxy.
It does not execute the applications.

## Historical preservation evidence

`checks/server-baseline.json` remains the immutable historical server control.
The removed preservation harness compared an agents-and-web-disabled counterfactual with the previous homelab System identity.
The System inputs remain frozen; current checks do not repeat whole-System comparisons.

`checks/homelab-agent-delta.json` enumerates the permitted Home package and file changes.
It also fixes the complete Home generation, profile, NixOS user-package list, and Home Manager activation-unit identity.
`checks/homelab-web-delta.json` separately fixes the dedicated account, group, service unit, confinement drop-in package, and Caddy route.
These JSON records remain historical evidence, not active check expectations.
The owner requested basic Nix evaluation instead of the whole-Host and negative-case harness.
Do not refresh the historical baseline or the Home delta to hide an unexplained change.

Those records predate the migration to current Home Manager and Home modules.
They do not constrain the current Home generation or establish that the new Home preserves historical behavior.

## Shared terminal and web service

ADR-0009 records the owner's decision to share their existing personal OpenCode service between the SSH TUI and web UI.
The earlier dedicated non-sudo identity did not share sessions or provider connections.
Homelab now disables `dotfiles.coding-agents.web.enable`; the optional isolated execution mode remains available but is not deployed here.
Neither the old database nor `/var/lib/opencode-web.env` is deleted or copied into the personal service.

`hosts/homelab/services/opencode.nix` owns the host-specific service identity and ingress configuration.
It installs the `opencode.service` Home Manager user unit for `fveracoechea` and enables lingering so the service starts without an SSH login.
The unit runs the same OpenCode package as the TUI, using `serve --service --hostname 127.0.0.1 --port 49374`.
Its pre-start command stops an existing unmanaged personal service before systemd takes ownership.
The service retains the owner's normal OpenCode data, configuration, state, and private service password.
No alternate database or provider credential store is configured.
Its PATH includes the managed Home profile and System tools.

The Caddy route for `opencode.veracoechea.com` forwards to that same loopback port.
It reuses the existing wildcard certificate and permits only socket peers in `100.64.0.0/10`.
Other peers receive HTTP 403, including ordinary LAN clients.
Forwarding headers do not grant access, and tailnet IPv6 addresses do not match the IPv4 rule.
No new firewall port, DNS entry, or router change is required.
Other virtual hosts retain their existing access rules.

**Browser sessions now have the owner's personal account access, including passwordless sudo authority.**
The dedicated service's confinement is not a security boundary for this shared personal service.
Provider sign-ins and sessions belong to the same database, so changes in either interface appear in both.

## Pairing and operation

On the homelab, run:

```sh
opencode pair --url https://opencode.veracoechea.com
```

Open the generated single-use link in the desktop browser.
The `--url` option changes the address in the link, not the service that issues the code.
It is correct here because Caddy and the local CLI now reach the same personal service.
Pair again after this migration; cookies issued by the retired isolated service use a different signing password.
Do not publish pairing links, passwords, or provider tokens.

The ordinary `opencode` TUI discovers the same registered personal service without additional flags.
Check it with `opencode service status` and `opencode api get /api/info`.
Use `systemctl --user status opencode` to inspect its supervisor.
Use `systemctl --user stop opencode` to stop it deliberately; the unit restarts when its process exits otherwise.
Service configuration changes may trigger that automatic restart.

The evaluation check asserts lingering, the enabled user unit, private file permissions, and the absence of the isolated system service.
It also records the shared unit and proxy configuration alongside both hosts' coding-agent settings.
Historical delta files remain unchanged.

## Runtime acceptance

Server activation still requires owner authorization under `server-consolidation.md`.
The owner explicitly authorized this shared-service migration and its brief OpenCode restart.
Before activation, back up both OpenCode databases and retain the active System generation.
Compare the candidate service changes with the running generation before switching.

After activation, verify:

1. The user unit is active and enabled, and lingering is enabled.
2. The backend listens only on loopback, while unauthenticated and incorrect-password API requests fail.
3. The local API and HTTPS API report the same process, session IDs, and OpenAI connection.
4. A fresh browser-style pairing cookie authenticates through HTTPS without logging secrets.
5. Non-tailnet requests remain forbidden, including requests with forged forwarding headers.

Browser rendering, model generation, reboot recovery, native subagents, and Operator readiness are separate runtime checks.
Operator dispatch still requires an appropriate live Herdr context; sharing a server alone does not establish that context.
Do not claim these checks passed without running them.

Sources: <https://opencode.ai/v2/docs/cli/web>, <https://opencode.ai/v2/docs/troubleshooting>, and the selected executable's source.

## Deployment verification

The owner authorized activation on 2026-11-13.
`nix flake check`, the remote System build, and activation passed.
The local and HTTPS APIs reported the same process, both original session IDs, and the original OpenAI connection ID.
HTTP checks passed for browser-style pairing, the session cookie, authenticated event streaming, incorrect-password rejection, and non-tailnet rejection with forged forwarding headers.
The user unit was active and enabled, lingering was enabled, and its restart count was zero.
The retired service was stopped and its database remained in place.
The other checked application services remained active; this was not application-level acceptance testing.

Root-only database and service-credential backups are under `/var/backups/opencode-shared-20261113T071927Z` on the homelab.
Both SQLite snapshots passed `PRAGMA quick_check`; restore was not rehearsed.
No browser automation, model generation, reboot, or Operator dispatch test ran.
