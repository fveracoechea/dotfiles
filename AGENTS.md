This is a NixOS/nix-darwin dotfiles repository using flakes

## Guidelines

- Never build system config, the user should do it
- Naming: Use descriptive function names, kebab-case for file names
- Comments: Minimal inline comments, prefer self-documenting code
- Only do system changes using the nix config flake
- Test config: `nixos-rebuild test --flake .#nixos-desktop` or `darwin-rebuild check --flake .#macbook-pro`
- Check flake: `nix flake check`
- Neovim lua config checks `nix flake check`
- You can ssh into homelab host machine by doing "ssh homelab" nix config: ~/Code/homelab
- You can ssh into hostinger VSP machine by doing "ssh hostinger"

## Agent skills

### Issue tracker

Issues live in the repo's GitHub Issues (uses `gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Default canonical labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context repo: `CONTEXT.md` at root + `docs/adr/` for ADRs. See `docs/agents/domain.md`.
