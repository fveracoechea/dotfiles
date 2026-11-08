set shell := ["bash", "-euo", "pipefail", "-c"]
set positional-arguments

# List available recipes.
default:
    @just --list

# Evaluate all hosts and checks without building or activating Systems.
evaluate:
    nix flake check --no-build

# Build and run the flake checks. Does not activate Systems.
check:
    nix flake check

# Print evaluated host manifests as JSON.
manifests:
    nix eval --json .#lib.hostManifests

# Run the Neovim Lua checks and smoke tests.
check-lua system="x86_64-linux":
    bash scripts/check-lua.sh "$1"

# Run the isolated Neovim first-launch test with real plugin downloads.
check-neovim-runtime:
    bash scripts/check-neovim-runtime.sh

# Run the Hyprland baseline script: capture <dir>, validate <dir>, or test.
hyprland-baseline +args:
    bash scripts/capture-hyprland-baseline.sh "$@"

# Activate the desktop temporarily. Services can change persistent data.
[confirm("Activate the desktop temporarily?")]
test-desktop: evaluate
    sudo nixos-rebuild test --flake .#nixos-desktop

# Activate the desktop configuration permanently.
deploy-desktop: evaluate
    sudo nixos-rebuild switch --flake .#nixos-desktop

# Activate homelab services after backup and recovery validation.
deploy-homelab target="homelab": evaluate
    nixos-rebuild switch --flake .#homelab --build-host "$1" --target-host "$1" --sudo

# Activate VPS services. Use target hostinger until the vps SSH alias is installed.
deploy-vps target="vps": evaluate
    nixos-rebuild switch --flake .#vps --target-host "$1" --sudo
