This is a NixOS/nix-darwin dotfiles repository using flakes
## Guidelines
- Never build system config, the user should do it 
- Naming: Use descriptive function names, kebab-case for file names
- Comments: Minimal inline comments, prefer self-documenting code
- Test config: `nixos-rebuild test --flake .#nixos-desktop` or `darwin-rebuild check --flake .#macbook-pro`
- Check flake: `nix flake check`

## Neovim lua config checks

The flake exposes two `checks` derivations per system that validate the lua
config under `modules/home-manager/neovim/config/`:

- `neovim-lua-lint` — runs `stylua --check` (format drift, config in
  `.stylua.toml`) and `luacheck` (static analysis, config in `.luacheckrc`).
- `neovim-smoke-test` — builds a self-contained `wrapNeovim` with the
  home-manager plugin set, then `require`s every module from `init.lua`
  headlessly and fails on any error.

Run them with:

```sh
nix flake check                            # runs all checks, including these
nix build .#checks.x86_64-linux.neovim-lua-lint
nix build .#checks.x86_64-linux.neovim-smoke-test
# or:
scripts/check-lua.sh
```

When editing lua: run `stylua modules/home-manager/neovim/config/` to format,
then `scripts/check-lua.sh` to validate. Add new `require` targets to the
`modules` array in `checks/neovim.nix` when new plugin/config files are added.

## Agent skills

### Issue tracker

Issues live in the repo's GitHub Issues (uses `gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Default canonical labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context repo: `CONTEXT.md` at root + `docs/adr/` for ADRs. See `docs/agents/domain.md`.

