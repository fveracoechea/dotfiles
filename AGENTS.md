This is a Linux dotfiles repository using Nix flakes.

## Guidelines

- Comments: Minimal inline comments, prefer self-documenting code
- Only do system changes using the nix config flake
- User-only config test: `nixos-rebuild test --flake .#nixos-desktop`
- Check flake: `nix flake check`
- Neovim lua config checks `nix flake check`
- Commit most changes and push them to main.
- SSH to the VPS with `ssh vps`.
- SSH to the homelab with `ssh homelab`.

## Agent skills

### Issue tracker

Issues live in the repo's GitHub Issues (uses `gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Default canonical labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context repo: `GLOSSARY.md` at root + `docs/adr/` for ADRs. See `docs/agents/domain.md`.
