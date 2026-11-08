#!/usr/bin/env bash
# Run the neovim lua config feedback loops via the flake checks output.
# Usage: scripts/check-lua.sh [system]
set -euo pipefail

SYSTEM="${1:-$(nix eval --impure --raw --expr 'builtins.currentSystem')}"

nix build --impure --no-link --print-out-paths \
  "path:.#checks.${SYSTEM}.neovim-lua-lint" \
  "path:.#checks.${SYSTEM}.neovim-smoke-test" \
  "path:.#checks.${SYSTEM}.neovim-lock-seed"
