# Non-Nix Config Files in Top-Level `config/` Directory

Application configuration files that are not Nix (lua, json, toml, etc.) live in a top-level `config/` directory at the project root, namespaced per application (e.g. `config/nvim/`). Each Home Manager module installs its application's directory into the Nix store via `xdg.configFile` with a repo `source` path (e.g. `xdg.configFile."nvim" = { recursive = true; source = ../../config/nvim; }`), rather than embedding the files as Nix string literals (`xdg.configFile."...".text = builtins.toJSON { ... }`).

## Trade-offs

This trade-off favors editability and native tooling over pure-eval authoring. Config files are authored and maintained in their native format with full LSP, formatter, and treesitter support - no Nix string escaping, no `builtins.toJSON` plumbing. Edits reach the application on the next rebuild, which also picks up plugin and package changes.

The cost is that edits to these files reach the application on the next rebuild, not immediately. They are still version-controlled and reproducible in the flake sense (the store copy comes from the repo source), and a consumer can reconstruct the full configuration from `nix eval`. Tooling that needs the config path (flake checks, lint scripts) must reference `config/<app>/` rather than the module directory.

Neovim's plugin lockfile is the exception to store-backed deployment.
`vim.pack` opens that file directly for writing, so the desktop links it to the tracked file in its checkout.
The rejected store-backed lockfile would prevent updates.
The accepted cost is an explicit checkout path and plugin-update diffs in the working tree.
The rest of the Neovim directory stays writable for sessions and contains individual store-backed configuration links.

## Rejected alternatives

- **Nix-embedded config (`xdg.configFile.text`)** - rejected for non-trivial configs like the neovim lua config: string-escaped Nix literals lose editor intelligence, formatter support, and treesitter highlighting, and grow unwieldy as the config grows. Small generated configs such as Sunshine apps.json and Hunk still use this pattern because they are data, not hand-edited source.
- **In-module `config/` subdirectory (`modules/home-manager/<app>/config/`)** - rejected because it couples the config files to the module path, making the module directory a mix of Nix and non-Nix source, and making the config harder to find and tool. A single top-level `config/` mirrors the XDG layout and keeps all non-Nix source in one place.
