#!/usr/bin/env bash
# Run the neovim lua config feedback loops via the flake checks output.
# Usage: scripts/check-lua.sh [system]
set -euo pipefail

SYSTEM="${1:-$(nix eval --impure --raw --expr 'builtins.currentSystem')}"

nix build --impure --no-link --print-out-paths \
  ".#checks.${SYSTEM}.neovim-lua-lint"

nix build --impure --no-link --print-out-paths \
  ".#checks.${SYSTEM}.neovim-smoke-test"
