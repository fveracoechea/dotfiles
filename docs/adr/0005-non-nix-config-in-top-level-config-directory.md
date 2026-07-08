# Non-Nix Config Files in Top-Level `config/` Directory

Application configuration files that are not Nix (lua, json, toml, etc.) live in a top-level `config/` directory at the project root, namespaced per application (e.g. `config/nvim/`). Each Home Manager module symlinks its application's directory into place via `config.lib.file.mkOutOfStoreSymlink`, pointing at the real files in the repo rather than embedding them as Nix string literals (`xdg.configFile."...".text = builtins.toJSON { ... }`).

## Trade-offs

This trade-off favors editability and native tooling over pure-eval reproducibility. Config files are authored and maintained in their native format with full LSP, formatter, and treesitter support - no Nix string escaping, no `builtins.toJSON` plumbing. The out-of-store symlink means edits to these files are live on the next editor reload without a Home Manager rebuild (though plugin or package changes still require one).

The cost is that these config files are real files on disk, not values produced by the Nix eval. They are still version-controlled and reproducible in the flake sense (the symlink target is a repo path), but a consumer cannot reconstruct the full configuration from `nix eval` alone. Tooling that needs the config path (flake checks, lint scripts) must reference `config/<app>/` rather than the module directory.

## Rejected alternatives

- **Nix-embedded config (`xdg.configFile.text`)** - rejected for non-trivial configs like the neovim lua config: string-escaped Nix literals lose editor intelligence, formatter support, and treesitter highlighting, and grow unwieldy as the config grows. Small generated configs (e.g. karabiner, sunshine apps.json, hunk) still use this pattern because they are data, not hand-edited source.
- **In-module `config/` subdirectory (`modules/home-manager/<app>/config/`)** - rejected because it couples the config files to the module path, making the module directory a mix of Nix and non-Nix source, and making the config harder to find and tool. A single top-level `config/` mirrors the XDG layout and keeps all non-Nix source in one place.
