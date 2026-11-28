# Server deployment readiness

The readiness operation rejects service downgrades and requires owner acceptance before either server deployment recipe activates services.
Preparation does not select a new release or authorize a cutover.

Both hosts remain `preserved` in `checks/server-migrations.json`.
Their System module trees still use the immutable `nixpkgs-servers` revision.
The shared Release Channel remains `nixos-26.05`.
Homelab's Home already uses current Home Manager and the Latest Channel.

## Inspect without activation

```sh
just server-readiness homelab
just server-readiness vps
just server-readiness vps hostinger

# Inspect the Release Channel without selecting it for deployment.
just server-readiness homelab homelab release
just server-readiness vps vps release

# Evaluate a candidate locally, without SSH or System builds.
nix eval --json .#lib.serverCandidates.homelab
```

These operations can fetch inputs and populate the local Nix store.
They do not build Systems, start services, migrate data, pull container images, or read secret files.
An evaluation failure rejects the candidate without changing the preserved hosts.
The current 26.05 homelab candidate fails because its Immich package is insecure.
Do not permit insecure packages to make that candidate pass.

The JSON report includes:

- The canonical host, SSH target, immutable source snapshot, candidate System path, and derivation.
- Fresh deployed evidence, its provenance, and the active, profile, and final System identities.
- Every version comparison and all collected blockers.
- Separate version and configuration-compatibility results.
- An owner-acceptance template bound to that candidate and deployed evidence.

Version success is not operational acceptance.
Missing inventory, failed probes, unknown versions, stale evidence, and mismatched identities block readiness.
The historical `checks/server-baseline.json` supplies additional minimum versions; it does not substitute for live evidence.

## Inventory and probes

`scripts/server-readiness/manifest.nix` resolves the configured packages rather than unrelated nixpkgs defaults.
The same manifest is exported for inspection and installed at `/etc/dotfiles/server-manifest.json` when the owner deploys.
It includes application packages, selected Node.js and Python dependencies, Home Assistant integrations, selected ROCm libraries, and PostgreSQL extensions.
Vaultwarden's selected database backend and web client are included.
Service and configuration values are hashed before publication.
Secret-reference paths are not secret contents.

The collector reads the manifest from the running generation.
It checks service state, configured executable paths, and `/proc` executable identities.
It resolves interpreter symlinks, including Node.js wrappers that point to `nodejs-slim`.
PostgreSQL probes run read-only SQL and compare live installed extensions.
Container probes return running state, registry digests, and image configuration IDs, not environment values.

PostgreSQL stays on major 17.
Installed `vector` and `vchord` versions must not exceed their candidate extension versions.
Unknown installed extensions block review.
Paperless-gpt must retain the accepted registry manifest digest.
A local image configuration ID cannot replace it.

`checks/server-npm-locks.json` records the reviewed Z-Wave driver version from the selected server's dependency lock.
The source hash and npm dependency hash must match.
A different lock blocks readiness until its driver version is reviewed.

The managed inventory covers host application service files and their explicitly tracked dependencies.
A new unregistered Nix file in `hosts/<host>/services/` blocks readiness.
Untracked enabled application services and Redis instances also block readiness.
The manifest classifies the known base infrastructure separately from managed applications.
Home-owned OpenCode and Browse remain outside the System-service version gate.
Boot, SSH, networking, storage, proxy behavior, and paired-service compatibility remain part of owner review.
This is not an inventory of every upstream `services.*` option or every transitive dependency.

Numeric components compare numerically, with trailing zero components treated equally.
The comparator supports dotted versions, `YYYY-MM-DD` dates, and `dev`, `alpha`, `beta`, `pre`, and `rc` prereleases.
A prerelease sorts below its final version.
Build metadata does not affect ordering.
The ROCm compiler's `-rocm` suffix is supported.
Other formats and package-family changes block readiness.

## Bootstrap existing generations

Existing deployments predate the installed manifest.
Do not activate a System merely to create evidence.
Instead, reconstruct the exact deployed generation from its immutable original source.

The helper evaluates that source without adding the new manifest module to its System.
For the historical homelab baseline:

```sh
nix eval --json --impure --expr '
  (import ./scripts/server-readiness/bootstrap.nix) {
    deployedFlake = "github:fveracoechea/homelab/4901bf69ae42c85789c0b7452100054d9a6b4ed3";
    host = "homelab";
    selector = "homelab";
  }
' > /tmp/opencode/homelab-bootstrap.json
```

Use `host = "vps"` and the original source's `selector = "hostinger"` for the historical VPS generation.
These are historical examples, not claims about the currently running hosts.
Use the actual immutable deployed source if either host changed.
The original nixpkgs input defaults to `nixpkgs`; supply `nixpkgsInput` if that source uses another name.

As the owner:

1. Verify that the emitted `systemPath` exactly matches the running generation.
2. Review the source, manifest completeness, selected packages, and generated configuration.
3. Fill the empty `reviewedBy` field only after that review.
4. Save the reviewed file as `$STATE/<host>-bootstrap.json`.
5. Run the read-only readiness operation.

`$STATE` means `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/server-readiness`.
The collector checks the bootstrap generation against the actual running generation.
It still performs fresh service, database, and container probes.
A stale bootstrap for another generation blocks readiness.
Stop if the original generation cannot be reproduced or its inventory cannot be established.

After a guarded deployment installs a manifest, the collector uses that installed manifest instead.

## Owner acceptance and deployment

Keep acceptance records outside the flake source.
Putting a candidate-bound receipt inside its own source would change the candidate it approves.
Keep these files private and do not store secret values in them.

1. Finish branch changes and candidate selection.
2. Run readiness and save its JSON report.
3. Complete the owner-run build, compatibility, backup, restore, independent-access, and retained-generation checks.
4. Review Immich with machine learning, Headscale with Headplane, Home Assistant with Z-Wave JS, and Ollama with ROCm.
5. Copy `acceptanceTemplate` to `$STATE/<host>-acceptance.json`.
6. Set each completed check to `accepted` and record concrete evidence for it.
7. For a Release Channel candidate, record final-release verification for its exact locked revision.
8. Repeat readiness after any source, lock, target, manifest, or deployed-evidence change.
9. Deploy each host separately during the owner maintenance window.

Do not mark backup or restore checks accepted merely because the version report passes.
Do not fill acceptance records automatically.

```sh
# Owner only. These commands build Systems and activate real services.
just deploy-vps
just deploy-homelab
```

Both deployment recipes run `just evaluate` and the same readiness operation.
Homelab retains its remote build host; the VPS retains its existing build location.
The operation builds the frozen candidate, verifies its output identity, and rechecks the checkout and deployed evidence before invoking activation.
Activation uses the immutable source snapshot that passed the check.
There is no ordinary bypass flag.
Arbitrary activation commands outside these recipes are not enforced.
Independent concurrent changes on a remote host are not a transactional deployment lock.

After activation, complete the existing smoke tests and reboot acceptance in [server-consolidation.md](server-consolidation.md).
Only after owner acceptance, capture fresh readiness evidence and save `deployedEvidence` as `$STATE/<host>-accepted.json`.
Retain earlier accepted records separately for audit and recovery.
The accepted manifest supplies additional version floors for later deployments.
Evaluation, rejected candidates, builds, and rebuild exit codes never update these records.

## Select the released channel later

Release publication does not change either host automatically.

1. Verify the official final release and support status.
2. Change the existing `nixpkgs-stable` input to the named released channel and update only that input.
3. Review the shared desktop change and complete ADR-0007's desktop acceptance.
4. Inspect both isolated server candidates and review their exact versions and compatibility.
5. Change only an accepted host's status from `preserved` to `release`.
6. Regenerate its acceptance receipt for that final active configuration.
7. Complete owner-only recovery, build, activation, and reboot acceptance.

The VPS release candidate uses the separately locked `disko` input, which follows the Release Channel.
Its preserved configuration still uses `server-disko`.
Review storage and boot equivalence before selecting the candidate.
Homelab's release candidate uses the current shared System modules.
The preserved homelab configuration retains its compatibility System source.

Retain all State Versions.
Remove compatibility inputs only after no preserved host consumes them and ADR-0008's removal conditions pass.
Do not mix individually retained Latest Channel services into the new System module tree.

## Automated checks

```sh
python3 scripts/server-readiness/gate_test.py
python3 scripts/server-readiness/mutation_test.py
nix flake check
```

The flake check also supplies the real evaluated active manifests to the command tests.
Fixtures replace Nix, SSH, and rebuild executables at process boundaries.
The tests use both actual `just` deployment recipes and record activation instead of performing it.
They do not build Systems or use live service data.
Mutation checks prove that the tests reject broken downgrade and source-binding guards.
