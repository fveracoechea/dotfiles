#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source=$(nix eval --impure --raw --expr "
  let flake = builtins.getFlake \"path:$repo\";
  in flake.inputs.neovim.outPath
")
editor=$(nix build --impure --no-link --print-out-paths --expr "
  let flake = builtins.getFlake \"path:$repo\";
  in flake.nixosConfigurations.nixos-desktop.config.home-manager.users.fveracoechea.programs.neovim.finalPackage
")
NVIM_BIN="$editor/bin/nvim" bash "$source/scripts/check-runtime.sh"
