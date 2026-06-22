{
  lib,
  pkgs,
  inputs,
  system,
}: let
  flake = inputs.self;

  hmLib = inputs.home-manager.lib;

  pkgs' = pkgs;

  home = hmLib.homeManagerConfiguration {
    pkgs = pkgs';
    modules = [
      {
        home.username = "neovim-test";
        home.homeDirectory = "/tmp/neovim-test";
        home.stateVersion = "25.05";
        imports = ["${flake.outPath}/modules/home-manager/neovim/default.nix"];
        dotfiles.neovim.enable = true;
      }
    ];
  };

  # Build a self-contained nvim with the same plugin set the home-manager
  # config would install, plus the repo's lua config on the runtimepath.
  # This lets the headless smoke test run in pure eval, no real HOME needed.
  cfg = home.config.programs.neovim;
  configDir = flake.outPath + "/modules/home-manager/neovim/config";

  testNvim =
    pkgs'.wrapNeovim cfg.finalPackage.unwrapped {
      viAlias = false;
      vimAlias = false;
      configure = {
        customRC = ''
          let &runtimepath = '${configDir},' . &runtimepath
        '';
        packages.home-manager = {
          start = lib.pipe cfg.plugins [
            (builtins.filter (p: p != null))
            (map (p:
              if builtins.isAttrs p && p ? plugin
              then p.plugin
              else p))
          ];
        };
      };
    };

  smokeTest =
    pkgs'.runCommand "neovim-config-smoke-test" {
      nativeBuildInputs = [testNvim];
      nvimBin = "${testNvim}/bin/nvim";
      configDir = configDir;
    } ''
      set -euo pipefail
      export HOME=$PWD
      export NVIM_DATA_DIR=$PWD/data
      mkdir -p "$NVIM_DATA_DIR"

      modules=(
        config.options
        config.keymaps
        config.autocmds
        config.lsp
        plugins.miscellaneous
        plugins.mini
        plugins.snacks
        plugins.catppuccin
        plugins.conform
        plugins.codesnap
        plugins.treesitter
        plugins.lualine
        utils.lsp-capabilities
      )

      code=0
      for m in "''${modules[@]}"; do
        "$nvimBin" --headless -u NONE \
          +"let &runtimepath = '$configDir,' . &runtimepath" \
          +"lua local ok, err = pcall(require, '$m')
            if not ok then io.stderr:write('$m: ' .. tostring(err) .. '\n'); vim.cmd('cquit 1') end" \
          +qa || { echo "FAIL: $m" >&2; code=1; }
      done

      if [ "$code" -eq 0 ]; then
        echo "all modules loaded successfully" > "$out"
      else
        exit "$code"
      fi
    '';

  luaCheck =
    pkgs'.runCommand "neovim-lua-lint" {
      nativeBuildInputs = with pkgs'; [stylua luaPackages.luacheck];
      configDir = configDir;
      luacheckrc = flake.outPath + "/.luacheckrc";
      HOME = "$TMPDIR";
    } ''
      set -euo pipefail
      stylua --check "$configDir"
      luacheck --config "$luacheckrc" --no-cache "$configDir"
      touch "$out"
    '';
in {
  neovim-smoke-test = smokeTest;
  neovim-lua-lint = luaCheck;
}
