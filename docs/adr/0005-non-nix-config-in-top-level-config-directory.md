# Non-Nix Config Files in Top-Level `config/` Directory

Status: accepted. Amended 2026-11-08: shared Neovim configuration belongs to its own repository and supports both Nix and non-Nix installation.

Application configuration files that are not Nix (lua, json, toml, etc.) live in a top-level `config/` directory at the project root, namespaced per application (e.g. `config/hypr/`). Each Home Manager module installs its application's directory into the Nix store via `xdg.configFile` with a repo `source` path, rather than embedding the files as Nix string literals (`xdg.configFile."...".text = builtins.toJSON { ... }`).

## Trade-offs

This trade-off favors editability and native tooling over pure-eval authoring. Config files are authored and maintained in their native format with full LSP, formatter, and treesitter support - no Nix string escaping, no `builtins.toJSON` plumbing. Edits reach the application on the next rebuild, which also picks up plugin and package changes.

The cost is that edits to these files reach the application on the next rebuild, not immediately. They are still version-controlled and reproducible in the flake sense (the store copy comes from the repo source), and a consumer can reconstruct the full configuration from `nix eval`. Tooling that needs the config path (flake checks, lint scripts) must reference `config/<app>/` rather than the module directory.

Neovim configuration is shared with the non-Nix macOS consumer and has a separate owner repository.
Both consumers use the same native Lua source and committed plugin lockfile rather than maintaining copies.
The plugin lockfile remains writable because Neovim's plugin manager writes it directly.
Normal installations advance an unchanged lockfile with the selected configuration revision and reject local edits.
Plugin updates belong to the shared repository; development installations may link its writable lockfile explicitly.
Runtime state stays separate from the shared source.

## Rejected alternatives

- **Nix-embedded config (`xdg.configFile.text`)** - rejected for non-trivial configs like the neovim lua config: string-escaped Nix literals lose editor intelligence, formatter support, and treesitter highlighting, and grow unwieldy as the config grows. Small generated configs such as Sunshine apps.json and Hunk still use this pattern because they are data, not hand-edited source.
- **In-module `config/` subdirectory (`modules/home-manager/<app>/config/`)** - rejected because it couples the config files to the module path, making the module directory a mix of Nix and non-Nix source, and making the config harder to find and tool. A single top-level `config/` mirrors the XDG layout and keeps all non-Nix source in one place.
