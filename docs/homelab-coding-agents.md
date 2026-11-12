# Homelab coding agents

Homelab uses the current coding-agent capability in its existing NixOS-integrated Home.
Its System, Home Manager, and compatibility inputs remain frozen under ADR-0008.
Unrelated desktop behavior must remain unchanged.
The recovered content includes main's native supervisor/worker modes and OpenAI compaction policy, with a 25% buffer and 20000 kept tokens.
Operator and its coupled agent prompts use the authorized stable v2.3.2 release.
Herdr notification sound is disabled without changing its visual notification policy.
These ordinary content edits do not resolve the root PR's separate Git ancestry conflict or establish default-branch readiness before landing.

## Compatibility adapter

`modules/coding-agents/home-compat.nix` replaces only the historical coding-agent subtree.
Its disabled-module identifier is the imported directory, not that directory's `default.nix` file.
Using the latter leaves duplicate declarations and the historical Claude implementation available.
The compatibility aggregate and its unrelated Home implementations remain installed.

The adapter supplies current tool packages and sources without replacing server `pkgs`, `lib`, or `dotfilesPkgs`.
Both Home entry files share tool policy, CLI preferences, skills, Herdr integration, and Hunk settings.
The pinned OpenCode module has no `cli` or `validateFiles` options.
The adapter generates `cli.json` through `xdg.configFile` and validates it against the selected executable's schema during its build.
The capability check evaluates the selected Home settings and web service options without executing the applications.
Skill directories use explicit directory links because the pinned renderer probes unrealized package paths during evaluation.
Instructions use an explicit source because the pinned renderer treats a string path as inline text.

The frozen Git implementation already installs Hunk and GitHub CLI.
When coding agents are enabled, the adapter removes only those exact historical package entries.
It replaces the old Hunk configuration with current shared policy and preserves the existing Git/lazygit pager behavior.
It does not disable or duplicate the frozen Git implementation.
Remove this adapter when a separately reviewed server migration supplies the current Home Manager contract.

## Historical preservation evidence

`checks/server-baseline.json` remains the immutable historical server control.
The removed preservation harness compared an agents-and-web-disabled counterfactual with the previous homelab System identity.
The server inputs remain frozen; current checks do not repeat whole-System comparisons.

`checks/homelab-agent-delta.json` enumerates the permitted Home package and file changes.
It also fixes the complete Home generation, profile, NixOS user-package list, and Home Manager activation-unit identity.
`checks/homelab-web-delta.json` separately fixes the dedicated account, group, service unit, confinement drop-in package, and Caddy route.
These JSON records remain historical evidence, not active check expectations.
The owner requested basic Nix evaluation instead of the whole-Host and negative-case harness.
Do not refresh the historical baseline or the Home delta to hide an unexplained change.

The fontconfig file is an indirect profile-reference change, not a new font policy.
Pinned Home Manager embeds the Home profile path in its generated font directories and includes.
The added tools change that profile path, so its generated XML changes too.
All other font configuration remains unchanged.

## Requested web endpoint

The owner subsequently requested an OpenCode web server at `opencode.veracoechea.com`.
This supersedes the original assignment's prohibition on that endpoint, but not its unrelated preservation requirements.
The owner selected tailnet-only HTTPS and a dedicated non-sudo account in the recorded `web-access-model` answer.
These decisions are settled; they do not authorize activation or access to existing projects.

The System Module enables `opencode-web.service` through `dotfiles.coding-agents.web.enable`.
Its backend runs `opencode serve --hostname 127.0.0.1 --port 4096`.
The optional `web.port` and `web.environmentFile` settings belong to that module; host composition owns ingress.
The desktop does not enable the service.

`hosts/homelab/services/opencode.nix` adds the Caddy route for `opencode.veracoechea.com`.
It reuses the existing wildcard certificate and forwards only socket peers in `100.64.0.0/10`.
Other peers receive HTTP 403, including ordinary LAN clients.
Forwarding headers do not grant access.
This route permits IPv4 tailnet addresses only; tailnet IPv6 addresses do not match it.
The backend needs no new firewall opening, and no external DNS or router configuration was changed.
The existing proxy's other virtual hosts retain their existing access rules.

The dedicated `opencode-web` account has no supplementary groups, SSH keys, wheel membership, or Nix trusted-user grant.
Systemd protects the owner's Home, prevents privilege elevation, and restricts writes outside the service's private state.
Its filesystem confinement exposes only the selected runtime closure, private state, and explicit runtime files.
It does not expose the host's entire Nix store, `/srv`, `/opt`, or other existing project directories.
Read-only runtime bindings supply name resolution, account metadata, and `/usr/bin/env`; certificate roots come from the selected runtime closure.
The account owns `/var/lib/opencode-web`, with mode `0700` and a `0077` umask.
It starts in its own `workspace` directory.
Data, cache, and state use separate directories there; shared declarative configuration comes from the read-only Nix store.
No owner credentials, Home directory, Herdr socket, or existing project directories are mounted into the service.
These restrictions are configuration guarantees, not evidence of deployed isolation.

The required runtime file is `/var/lib/opencode-web.env`, outside the Nix store and the service-owned state directory.
The owner must provision it as root-owned, mode `0600`, with a nonempty `OPENCODE_PASSWORD` entry using systemd EnvironmentFile syntax.
The service account must not own or write that file.
The unit's required-file condition leaves the service dormant when the file is absent, without failing the service start or rebuild activation.
Systemd reads an existing file before starting the process.
An invalid or unreadable supplied file can fail startup and activation; the condition does not validate its contents.
The start wrapper also rejects an unset or empty password before creating a workspace or launching OpenCode.
OpenCode's Basic authentication username is `opencode`.
No password or provider credentials were generated, inspected, copied, or committed.
Provider credentials must belong to the dedicated identity and remain outside the declarative configuration.

Sources: <https://opencode.ai/v2/docs/cli/web>, <https://opencode.ai/v2/docs/cli/config>, and the locked executable's source.
Do not use the legacy `/web` documentation's authentication environment names as the V2 contract.

## Web workers and runtime limits

Native OpenCode subagents run in server-side child sessions under the service identity.
That does not establish support for Operator-dispatched WorkerAgents.
Operator dispatch requires a live Herdr socket and runtime context; this service supplies neither.
Its Operator plugin and skills do not create that context or authorize sharing the owner's socket.
The Home capability supplies terminal integration separately.
Validate native subagents and Operator readiness as separate acceptance checks for the selected agent mode.
Do not promise browser-to-Herdr dispatch, phone compatibility, disconnect recovery, or unattended restart recovery without runtime evidence.

`coding-agents-evaluation` evaluates Home settings, the web switch, its runtime-file path, and the configured service account.
The VM, runtime, formatter, and mutation harnesses are removed under the owner's evaluation-only acceptance.
The actual service's password guards and confinement settings are unchanged.
Configuration evaluation does not establish deployed isolation, HTTP authentication, or browser behavior.

## Owner acceptance before activation

**The shared wildcard tool permission requires owner review before activation.**
The managed Home retains the existing owner's passwordless wheel authority; the web service uses the separate restricted account.
The dedicated identity does not authorize access to the owner's existing projects or credentials.

After separately authorizing activation, the owner must:

1. Confirm the approved private route, certificate, and owner-managed DNS resolution from a tailnet client.
2. Provision the runtime password file and separate provider credentials without putting secrets into Nix or chat.
3. Check existing managed files and `hm-backup` collisions without deleting user configuration.
4. Verify provider, GitHub, Exa, and SSH credentials separately for each intended identity without copying the owner's credentials into the service.
5. Verify the existing Home Zsh secret source exists and has suitable permissions without inspecting its contents.
6. Check writable OpenCode, Herdr, and Operator state and the terminal's TERM, colors, resize, and reconnect behavior.
7. Complete the documented Operator project/integration setup and run its readiness checks in the intended Herdr context on homelab.
8. Verify Herdr/OpenCode working, idle, completion, and steering behavior in the full TUI, Mini, and automation modes separately.
9. Check the managed CLI file after changing settings because OpenCode can replace its symlink.
10. Confirm the backend listens only on loopback and cannot start with a missing or empty runtime password.
11. Reject unauthenticated and wrong-password requests; verify successful authenticated requests through the HTTPS route without logging credentials.
12. Verify LAN/public rejection, including requests with forged forwarding headers, and authenticated tailnet access.
13. Verify the service cannot read the owner's Home, SSH keys, provider state, or existing projects, or obtain sudo/Nix trusted-user authority.
14. Test browser streaming, phone layout, disconnect/reconnect behavior, and native subagents under the dedicated identity.

Operator issue <https://github.com/fveracoechea/operator/issues/332> concerns integration behavior outside this refactor.
The final content preserves main's native agent modes/compaction and sound-only change, and advances only Operator and its coupled prompts to v2.3.2.
Historical checks do not authorize restoring old inputs, prompts, or compaction settings.
A fix in another workspace does not prove the locked package passes the runtime checks above.
Acceptance for this refactor is basic Nix configuration evaluation, not full builds or another review round.
The owner decides when to merge; automated merge guards are separate from that decision.
No remote runtime, browser, authentication, or deployed security acceptance ran for this checkpoint.
Builds and evaluation do not establish credentials, deployed state, backup readiness, or safe activation.
