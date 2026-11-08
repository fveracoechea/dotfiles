#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
editor=$(nix build --impure --no-link --print-out-paths --expr "
  let flake = builtins.getFlake \"path:$repo\";
  in flake.nixosConfigurations.nixos-desktop.config.home-manager.users.fveracoechea.programs.neovim.finalPackage
")
mkdir -p /tmp/opencode
sandbox=$(mktemp -d /tmp/opencode/neovim-runtime.XXXXXX)
export HOME="$sandbox/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
export DOTFILES_PACK_GIT_TEST=1
mkdir -p "$XDG_CONFIG_HOME/nvim"
cp -R "$repo/config/nvim/." "$XDG_CONFIG_HOME/nvim/"
mv "$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json" "$sandbox/checkout-lock.json"
ln -s "$sandbox/checkout-lock.json" "$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json"

printf 'Isolated runtime test directory: %s\n' "$sandbox"
timeout 360 "$editor/bin/nvim" --headless \
  --cmd 'lua vim.g.dotfiles_smoke_errors = {}; local notify = vim.notify; vim.notify = function(msg, level, opts) if level == vim.log.levels.ERROR then vim.g.dotfiles_smoke_errors = vim.list_extend(vim.g.dotfiles_smoke_errors, { tostring(msg) }) end; return notify(msg, level, opts) end' \
  -c "lua dofile('$repo/checks/neovim-smoke.lua')" < /dev/null > "$sandbox/startup.log" 2>&1 || {
    cat "$sandbox/startup.log"
    exit 1
  }
cmp "$repo/config/nvim/nvim-pack-lock.json" "$sandbox/checkout-lock.json"
printf 'First-launch, parser compilation, and writable plugin-lock checks passed. Log: %s/startup.log\n' "$sandbox"
