# Homelab coding agents

Homelab uses the current coding-agent capability in its existing NixOS-integrated Home.
Its System, Home Manager, and compatibility inputs remain frozen under ADR-0008.
The desktop's evaluated System identity must remain unchanged.

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
The agents-disabled counterfactual must reproduce the previous homelab System identity.
The check also applies the pre-existing Paperless image-reference normalization before comparing with the historical control.
VPS identity and the immutable server input guards remain exact.

`checks/homelab-agent-delta.json` enumerates the permitted Home package and file changes.
It also fixes the complete Home generation, profile, NixOS user-package list, and Home Manager activation-unit identity.
The normalized enabled System restores only the verified Home profile and Home Manager unit.
Its full identity must match the agents-disabled System.
This comparison includes unrelated service closures, units, networking, authorization, secret references, and activation behavior.
The additional negative cases reject unrelated Home files, enabled-only environment changes, sudo changes, service-unit changes, firewall changes, secret-reference changes, and user-package additions.
Do not refresh the historical baseline or the Home delta to hide an unexplained change.

The fontconfig file is an indirect profile-reference change, not a new font policy.
Pinned Home Manager embeds the Home profile path in its generated font directories and includes.
The added tools change that profile path, so its generated XML changes too.
All other font configuration remains unchanged.

## Requested web endpoint

The owner subsequently requested an OpenCode web server at `opencode.veracoechea.com`.
This supersedes the original assignment's prohibition on that endpoint, but not its unrelated preservation requirements.
The web service and exposure are not implemented yet.
The recorded Operator question `web-access-model` requests the owner's access, service-identity, and secret-provisioning decisions.

Current V2 documentation uses `opencode serve`, which serves the browser interface and accepts `OPENCODE_PASSWORD`.
The locked executable is OpenCode 2.2.5; its Basic authentication username is `opencode`.
The proposed backend binds only to loopback behind existing Caddy TLS and refuses startup without an owner-provisioned password.
Existing wildcard TLS covers the requested name, but the repository does not establish public DNS or router forwarding.
The existing homelab proxy accepts LAN and tailnet traffic; its existing virtual hosts are not tailnet-only.
A private endpoint therefore needs an explicit access rule, not an assumption about the existing proxy.
No new listener, proxy route, DNS record, account, credential, firewall rule, or web service has been configured by this change yet.

Sources: <https://opencode.ai/v2/docs/cli/web>, <https://opencode.ai/v2/docs/cli/config>, and the locked executable's source.
Do not use the legacy `/web` documentation's authentication environment names as the V2 contract.

## Owner acceptance before activation

**Wildcard OpenCode tool permission and homelab's passwordless wheel sudo require explicit owner review before activation.**
Running the web service as the existing user would share that user's filesystem and privilege authority.
A separate account would require a separate decision about project access, state, and credentials.
Neither choice is implied by installing the terminal tools.

After separately authorizing activation, the owner must:

1. Resolve the web access, identity, password-file, and DNS questions before enabling exposure.
2. Check existing managed files and `hm-backup` collisions without deleting user configuration.
3. Verify provider, GitHub, Exa, and SSH credentials without copying them into the Nix store.
4. Verify the existing Zsh secret source exists and has suitable permissions without inspecting its contents.
5. Check writable OpenCode, Herdr, and Operator state and the terminal's TERM, colors, resize, and reconnect behavior.
6. Complete the documented Operator project/integration setup and run its readiness checks on homelab.
7. Verify Herdr/OpenCode working, idle, completion, and steering behavior in the full TUI, Mini, and automation modes separately.
8. Check the managed CLI file after changing settings because OpenCode can replace its symlink.
9. Test web authentication, rejected clients, proxy streaming, and the approved network access rules before using the endpoint.

Operator issue <https://github.com/fveracoechea/operator/issues/332> concerns integration behavior outside this refactor.
The attempted device update was cancelled after its release failed; this work retains the locked Operator source.
A fix in another workspace does not prove the locked package passes the runtime checks above.
Builds and evaluation do not establish credentials, deployed state, backup readiness, or safe activation.
