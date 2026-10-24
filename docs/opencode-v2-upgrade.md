# OpenCode v2 migration

## Applied configuration

Ran `nix flake update` on 2026-10-24.
Both hosts now select OpenCode **2.1.1** from `nixpkgs-latest` revision `901c54c08bdc20e00c2b3c73716b97497b1b3c74`.
This updated all flake inputs, including both Release Channel revisions.
System builds and activation remain user-only operations.
The equivalent Homebrew/stow migration is tracked in [macos-dotfiles#2](https://github.com/fveracoechea/macos-dotfiles/issues/2).

- Converted server settings to native v2 names and preserved high reasoning for the build agent and both configured providers.
- Preserved OpenRouter routing through `providers.openrouter.body.provider`.
- Moved terminal settings to `programs.opencode.cli`, including the saved Linux presentation preferences.
- Registered the v2 Herdr directory entrypoint through `cli.plugins` and removed the v1 plugin files and registration.
- Removed the obsolete environment flags, selected Exa through `websearch.provider`, and enabled the v2 todo tool.
- Converted the project's `nix-mcp` definition to `mcp.servers`.
- Retained only the requested `nixd` and TypeScript settings; v2 still has no working LSP runtime.
- Removed the v1-only Neovim OpenCode plugin and its keymaps, as requested.
- Enabled Home Manager validation against the configured OpenCode package's server and CLI schemas. [14] [15]

The Latest Channel's `mcp-nixos` cannot evaluate because its `fastmcp-slim` dependency is marked broken with MCP 2.
A temporary Channel Hold selects Release Channel `mcp-nixos` 2.4.3 on both hosts.
Return to the Latest Channel when that dependency supports MCP 2.
The DMS update renamed its bar component to `DBar`; the existing max-width patch now targets that path.

## Verification

Completed:

- `nix flake check`, including Neovim lint/smoke checks and the patched DMS/Hyprland check on Linux.
- Both hosts' OpenCode evaluations and the full Darwin system derivation evaluation.
- Generated global server and CLI files built and validated against OpenCode 2.1.1's bundled schemas.
- Project `opencode.json` validated against the same bundled server schema.
- Isolated OpenCode 2.1.1 `api --standalone config.get` loaded the generated native settings.
- Held `mcp-nixos` 2.4.3 completed MCP initialization and returned its `nix` and `nix_versions` tools.
- Nix formatting and whitespace checks.

Live provider calls, the full Herdr TUI lifecycle, and activation on either host remain pending.

## Activation

Run the host rebuild yourself.
For the desktop, first test the configuration, then stage the updated boot generation and reboot as required for a Release Channel update:

```sh
sudo nixos-rebuild test --flake .#nixos-desktop
sudo nixos-rebuild boot --flake .#nixos-desktop
sudo reboot
```

On the MacBook:

```sh
darwin-rebuild check --flake .#macbook-pro
darwin-rebuild switch --flake .#macbook-pro
```

After activation, quit old OpenCode processes and start OpenCode from a new terminal.
Check `opencode --version`, the selected high variant, provider access, the Nix MCP tools, and Herdr pane status.
An old process keeps its loaded v1 configuration.

## Initial research baseline

Checked on 2026-10-24 against OpenCode 2.0.32 source.
The package index reported 2.0.32, while the official website listed 2.1.4.
The original host pins selected 1.18.34.
The remaining research records the 2.0.32 baseline; the applied 2.1.1 migration is summarized above.

## Initial result

A package-only upgrade will lose the current LSP workflow and Herdr integration.
Update the Herdr client plugin deployment and terminal configuration before upgrading.
Decide whether project lint, typecheck, and compiler commands can replace agent LSP support.
The supported v1 server settings have an in-memory compatibility path, so a full native-format rewrite is optional. [1]

The findings below come from repository inspection and version-tagged source.
No live OpenCode 2.0.32 provider, MCP, or Herdr checks ran during that research.

## Migration findings

### Herdr plugin and terminal settings

OpenCode v2 replaces layered `tui.json` and `tui.jsonc` settings with one global `~/.config/opencode/cli.json`.
Its first-start migration reads global `tui.json` and saved preferences, but does not read `tui.jsonc`.
The v1 setup registered Herdr in `tui.jsonc`, so automatic migration would miss that registration. [1] [2]

The initial Home Manager pin had no `programs.opencode.cli` option. [3]
The updated module provides that option, which now owns the theme and plugin registration. [14]

```json
{
  "$schema": "https://opencode.ai/v2/cli.json",
  "theme": { "name": "system", "mode": "system" },
  "plugins": ["./herdr-opencode"]
}
```

The `name` selects terminal-palette colors, while `mode` selects automatic light/dark appearance. [4]
Inspect any existing `cli.json` and saved preferences before declaring the file.
An existing `cli.json` skips the initial import. [2]

`modules/home-manager/coding-agents/herdr.nix` now installs `opencode/herdr-opencode/tui.js` from the full `assets/opencode/herdr-tui-session.js`.
That file already exports a v2-compatible `setup(api)` implementation.
Register its directory, `./herdr-opencode`, in `cli.json.plugins`.
Copying the old single-file registration into `cli.json` does not work because v2 resolves a directory's TUI entrypoint. [5] [6]

The pinned upstream wrapper `assets/opencode/tui.js` imports `../herdr-tui-session.js`.
A direct source link to the full implementation avoids that relative import through store-backed symlinks. [5]

The removed legacy server plugin has a no-op v2 `setup()`.
Its v1 `chat.message` and `event` hooks do not run through the v2 loader.
Full-TUI compatibility does not establish Herdr reporting for local `run` or Mini mode. [7]

### LSP behavior loss

OpenCode 2.0.32 accepts `lsp` settings but does not run language servers, expose LSP tools, or return LSP diagnostics. [1]
The project tracks a v2 service port and has confirmed plans for LSP's return, with no public ETA found.
See [the LSP rationale research](opencode-lsp-removal.md) for maintainer statements and evidence limits.
The retained `nixd` and `typescript` entries in `opencode.nix` cannot restore those functions.
Retain v1 if agent LSP is required, or use project checks for diagnostics.
Do not treat successful config loading as proof that LSP is active.

### Environment flags and search

Neither `OPENCODE_ENABLE_EXA` nor `OPENCODE_EXPERIMENTAL_LSP_TOOL` has a runtime reference in the tagged package sources. [8]
Their assignments have been removed from `modules/home-manager/coding-agents/opencode.nix`.
For explicit Exa selection, v2 supports `websearch.provider = "exa"` and `EXA_API_KEY`.
The old enable flag does not select Exa. [9]
Live search authentication and provider access remain unverified.

## Supported existing settings

The following settings have source-verified compatibility paths in 2.0.32. [1] [10]

| Existing setting | Native v2 form |
| --- | --- |
| `autoupdate = false` | `update = "disable"` |
| `agent.build.model` and `variant = "high"` | `agents.build.model = "openai/gpt-6.1-sol#high"` |
| `permission."*" = "allow"` | `permissions = [{ action = "*"; resource = "*"; effect = "allow"; }]` |
| `provider` | `providers` |
| These models' `options` | `settings` |
| `variants.high = { ... }` | `variants = [{ id = "high"; settings = { ... }; }]` |
| `mcp.<name>` with `enabled = true` | `mcp.servers.<name>`, with `disabled = false` or omitted |

OpenAI and OpenRouter retain their provider IDs.
The current OpenRouter `options.extraBody.provider` routing object is retained by legacy migration, then moved into the request-body overlay by the native-provider rewrite.
Tagged tests cover OpenRouter routing overlays. [10] [11]
For a native rewrite, use `providers.openrouter.body.provider` with the existing routing fields.
OpenAI supports `settings.reasoningEffort`; OpenRouter supports `settings.reasoning.effort`. [12]
Actual model access, high-reasoning requests, and outgoing routing fields need live checks.

The root `opencode.json` local MCP definition supported a v1-form trial and is now in native v2 form.
The grep.app MCP definition was removed after the initial upgrade review.
The declared skills and global `AGENTS.md` paths remain supported. [1] [3]
Keep each provider, model, agent, or command entry entirely in one format when converting.
Supported v1 and native v2 entries can coexist at the top level. [1]

## Home Manager ownership

Server configuration migration runs in memory and does not rewrite the source files. [1]
Client settings writes use a temporary file and rename it over `cli.json`.
In a writable directory, this can replace a Home Manager symlink with a mutable file.
Keep persistent settings in the flake and check file ownership before the next activation. [2] [3]

The published schema accepts supported v1 and v2 shapes from 2.0.30 onward. [13]
Successful startup alone is insufficient because v2 can skip invalid or unsupported values while retaining other settings. [1] [10]

## Live acceptance checks still needed

- Check both providers and high variants, including the outgoing OpenRouter routing object.
- Invoke the configured MCP server through OpenCode and load the declared skills and global context.
- Check Herdr pane attribution, child-session status, blocked states, completion, reconnect, and cleanup in the full TUI.
- Check `run` and Mini reporting separately if used.
- Check `cli.json` ownership after a client settings change and before Home Manager activation.

Version 2.1.0 changed SDK/event/plugin contracts and restored `todowrite` behind `experimental.todo`; those were not 2.0.32 capabilities. [13]
The updated Herdr TUI implementation uses the session, execution, permission, and form APIs present in 2.1.1. [16]

## Primary sources

- [1] [OpenCode 2.0.32 migration guide](https://github.com/anomalyco/opencode/blob/v2.0.32/services/www/src/docs/content/migrate-v1.mdx).
- [2] [CLI migration](https://github.com/anomalyco/opencode/blob/v2.0.32/packages/cli/src/config/migrate.ts) and [CLI writes](https://github.com/anomalyco/opencode/blob/v2.0.32/packages/cli/src/config/config.ts).
- [3] [Pinned Home Manager OpenCode module](https://github.com/nix-community/home-manager/blob/dfadbe5162d5e86bc0808badec8f346f81b4b3f0/modules/programs/opencode.nix).
- [4] [Tagged theme guide](https://github.com/anomalyco/opencode/blob/v2.0.32/services/www/src/docs/content/cli/theme.mdx).
- [5] [Pinned Herdr full TUI implementation](https://github.com/herdrdev/herdr/blob/2563803dca97c040beaf3dc3acdcb5a3221b4238/src/integration/assets/opencode/herdr-tui-session.js) and [v2 wrapper](https://github.com/herdrdev/herdr/blob/2563803dca97c040beaf3dc3acdcb5a3221b4238/src/integration/assets/opencode/tui.js).
- [6] [TUI plugin loader](https://github.com/anomalyco/opencode/blob/v2.0.32/packages/tui/src/plugin/context.tsx#L332-L341) and [directory resolution](https://github.com/anomalyco/opencode/blob/v2.0.32/packages/plugin/src/host.ts).
- [7] [Pinned Herdr server asset](https://github.com/herdrdev/herdr/blob/2563803dca97c040beaf3dc3acdcb5a3221b4238/src/integration/assets/opencode/herdr-agent-state.js) and [v2 server plugin contract](https://github.com/anomalyco/opencode/blob/v2.0.32/packages/core/src/plugin/module.ts).
- [8] [Exact tagged source archive scanned for environment flags](https://codeload.github.com/anomalyco/opencode/zip/refs/tags/v2.0.32).
- [9] [Tagged websearch guide](https://github.com/anomalyco/opencode/blob/v2.0.32/services/www/src/docs/content/websearch.mdx) and [Exa plugin](https://github.com/anomalyco/opencode/blob/v2.0.32/packages/core/src/plugin/websearch/exa.ts).
- [10] [Config normalization](https://github.com/anomalyco/opencode/blob/v2.0.32/packages/core/src/config/normalize.ts), [legacy migration](https://github.com/anomalyco/opencode/blob/v2.0.32/packages/core/src/v1/config/migrate.ts), and [option splitting](https://github.com/anomalyco/opencode/blob/v2.0.32/packages/core/src/v1/config/provider-options.ts).
- [11] [Native extraBody rewrite](https://github.com/anomalyco/opencode/blob/v2.0.32/packages/core/src/aisdk-native.ts) and [OpenRouter overlay tests](https://github.com/anomalyco/opencode/blob/v2.0.32/packages/core/test/model-resolver.test.ts#L1225-L1254).
- [12] [OpenAI option handling](https://github.com/anomalyco/opencode/blob/v2.0.32/packages/ai/src/providers/openai-options.ts) and [OpenRouter runtime](https://github.com/anomalyco/opencode/blob/v2.0.32/packages/ai/src/providers/openrouter.ts).
- [13] [Official changelog](https://opencode.ai/changelog) and [tagged dual-format schema generator](https://github.com/anomalyco/opencode/blob/v2.0.32/packages/schema/script/config-schema.ts).
- [14] [Updated Home Manager OpenCode module](https://github.com/nix-community/home-manager/blob/2cd3234928f60bbff695a7ee56115ef7799c47cd/modules/programs/opencode.nix).
- [15] [OpenCode 2.1.1 migration guide](https://github.com/anomalyco/opencode/blob/v2.1.1/services/www/src/docs/content/migrate-v1.mdx).
- [16] [Updated Herdr TUI implementation](https://github.com/herdrdev/herdr/blob/5608de0608918aba2f9d501e7793b984a0ca9cfa/src/integration/assets/opencode/herdr-tui-session.js) and [OpenCode 2.1.1 TUI plugin API](https://github.com/anomalyco/opencode/blob/v2.1.1/packages/plugin/src/tui/context.ts).
