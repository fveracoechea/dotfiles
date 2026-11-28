set shell := ["bash", "-euo", "pipefail", "-c"]
set positional-arguments

# List available recipes.
default:
    @just --list

# Forward local ports 3001 and 3002 to homelab until Ctrl+C.
homescreen-tunnel:
    ssh -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -L 127.0.0.1:3001:127.0.0.1:3001 -L 127.0.0.1:3002:127.0.0.1:3002 homelab

# Evaluate all hosts and checks without building or activating Systems.
evaluate:
    nix flake check --no-build

# Build and run the flake checks. Does not activate Systems.
check:
    nix flake check

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

# Inspect readiness without building or activating Systems.
server-readiness host target=host selection="active":
    python3 scripts/server-readiness/gate.py check "$1" "$2" "$3"

# Activate homelab only after readiness and owner acceptance.
deploy-homelab target="homelab": evaluate
    python3 scripts/server-readiness/gate.py deploy homelab "$1"

# Activate VPS services. Use target hostinger until the vps SSH alias is installed.
deploy-vps target="vps": evaluate
    python3 scripts/server-readiness/gate.py deploy vps "$1"
