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
Flake checks also validate the generated server configuration and installed integration assets.
Skill directories use explicit directory links because the pinned renderer probes unrealized package paths during evaluation.
Instructions use an explicit source because the pinned renderer treats a string path as inline text.

The frozen Git implementation already installs Hunk and GitHub CLI.
When coding agents are enabled, the adapter removes only those exact historical package entries.
It replaces the old Hunk configuration with current shared policy and preserves the existing Git/lazygit pager behavior.
It does not disable or duplicate the frozen Git implementation.
Remove this adapter when a separately reviewed server migration supplies the current Home Manager contract.

## Preservation evidence

`checks/server-baseline.json` remains the immutable historical server control.
The agents-and-web-disabled counterfactual must reproduce the previous homelab System identity.
The check also applies the pre-existing Paperless image-reference normalization before comparing with the historical control.
VPS identity and the immutable server input guards remain exact.

`checks/homelab-agent-delta.json` enumerates the permitted Home package and file changes.
It also fixes the complete Home generation, profile, NixOS user-package list, and Home Manager activation-unit identity.
`checks/homelab-web-delta.json` separately fixes the dedicated account, group, service unit, confinement drop-in package, and Caddy route.
The normalized enabled System removes those verified web additions and restores the historical Home profile and Home Manager unit.
It removes only the enumerated confinement package, not arbitrary Systemd packages or their units.
Its full identity must match the agents-and-web-disabled System.
This comparison includes unrelated service closures, units, networking, authorization, secret references, and activation behavior.
The negative cases reject unrelated Home files, enabled-only environment changes, sudo changes, service-unit changes, firewall changes, secret-reference changes, and user-package additions.
They also reject a privileged web identity, public backend, unrestricted proxy, and enabled-only firewall change.
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

`coding-agents-web` checks the evaluated identity, state paths, privilege restrictions, missing/empty password rejection, and Caddy's adapted route.
It also verifies that isolation and proxy mutations fail their checks.
Address examples test the configured matcher, not live network packets.
These checks do not establish HTTP authentication behavior, deployed firewall rejection, namespace isolation, or browser streaming.

`coding-agents-web-isolation` runs a separate VM using the frozen System test framework and the evaluated service's filesystem restrictions.
It replaces the server command with a probe and omits the password-file requirement; it never starts an authenticated server or provisions credentials.
The probe rejects synthetic world-readable project, Home credential, unrelated-directory, and unrelated Nix-store files that the same account can read outside confinement.
It also writes private workspace/state files, reads immutable configuration, executes OpenCode's version command, initializes a Git repository, and loads certificate roots.
The VM separately verifies that the real service's absent runtime file skips startup without creating credentials or launching the server.
These are isolated-fixture filesystem results, not deployed acceptance or proof that every server operation works inside confinement.

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
Final cumulative builds and exact-head independent review must cover this updated content; earlier checkpoint results do not establish them.
Default-branch integration and genuine GitHub checks/non-author approval remain separate merge prerequisites.
No remote runtime, browser, authentication, or deployed security acceptance ran for this checkpoint.
Builds and evaluation do not establish credentials, deployed state, backup readiness, or safe activation.
