{
  lib,
  pkgs,
  inputs,
  system,
}: let
  home = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs.dotfilesPkgs = inputs.self.dotfilesPkgs.${system};
    modules = [
      ../modules/home-manager/neovim.nix
      {
        home.username = "neovim-test";
        home.homeDirectory = "/tmp/neovim-test";
        home.stateVersion = "25.05";
        dotfiles.neovim.enable = true;
      }
    ];
  };
  cfg = home.config.programs.neovim;
  configDir = ../config/nvim;
  lock = lib.importJSON (configDir + "/nvim-pack-lock.json");
  pluginSources = lib.mapAttrs (_: plugin:
    builtins.fetchGit {
      url = plugin.src;
      inherit (plugin) rev;
    })
  lock.plugins;
  languages = lib.pipe (lib.fileContents (configDir + "/lua/plugins/treesitter.lua")) [
    (lib.splitString "\n")
    (map (builtins.match ''[ ]+"([a-z_0-9]+)",''))
    (builtins.filter (match: match != null))
    (map builtins.head)
  ];
  parserFixtures = builtins.filter (grammar: builtins.elem grammar.language languages) pkgs.vimPlugins.nvim-treesitter.allGrammars;
  codesnapVersion = (builtins.fromTOML (lib.fileContents (pluginSources."codesnap.nvim" + "/project.toml"))).project.version;
  codesnapLibrary = pkgs.fetchurl {
    url = "https://github.com/mistricky/codesnap.nvim/releases/download/v${codesnapVersion}/linux-x86_64_generator.so";
    hash = "sha256-B8w5JBG9rWfsW+m1DXEzwhsXo7m8TWae9SJJq2X29Qg=";
  };
in {
  neovim-lock-seed = pkgs.runCommand "neovim-lock-seed" {} ''
    set -euo pipefail
    run() { "$@"; }
    ${home.config.home.activation.neovimPluginLock.data}
    cmp ${configDir}/nvim-pack-lock.json /tmp/neovim-test/.config/nvim/nvim-pack-lock.json
    echo updated > /tmp/neovim-test/.config/nvim/nvim-pack-lock.json
    ${home.config.home.activation.neovimPluginLock.data}
    test "$(cat /tmp/neovim-test/.config/nvim/nvim-pack-lock.json)" = updated
    echo linked > "$PWD/checkout-lock.json"
    rm /tmp/neovim-test/.config/nvim/nvim-pack-lock.json
    ln -s "$PWD/checkout-lock.json" /tmp/neovim-test/.config/nvim/nvim-pack-lock.json
    ${home.config.home.activation.neovimPluginLock.data}
    test -L /tmp/neovim-test/.config/nvim/nvim-pack-lock.json
    test "$(cat "$PWD/checkout-lock.json")" = linked
    touch "$out"
  '';

  neovim-smoke-test =
    pkgs.runCommand "neovim-config-smoke-test" {
      nativeBuildInputs = [cfg.finalPackage];
    } ''
      set -euo pipefail
      export HOME=$PWD/home
      export XDG_CONFIG_HOME=$HOME/.config
      export XDG_DATA_HOME=$HOME/.local/share
      export XDG_STATE_HOME=$HOME/.local/state
      export XDG_CACHE_HOME=$HOME/.cache
      mkdir -p "$XDG_CONFIG_HOME/nvim" "$XDG_DATA_HOME/nvim/site/pack/core/opt" "$XDG_DATA_HOME/nvim/site/parser"
      cp -R ${configDir}/. "$XDG_CONFIG_HOME/nvim/"
      chmod -R u+w "$HOME"

      # Exercise vim.pack offline with the lockfile's exact plugin sources.
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: source: ''
          cp -R ${source} "$XDG_DATA_HOME/nvim/site/pack/core/opt/${name}"
        '')
        pluginSources)}
      chmod -R u+w "$XDG_DATA_HOME"
      mkdir -p "$XDG_DATA_HOME/nvim/site/pack/core/opt/codesnap.nvim/lua/libs"
      cp ${codesnapLibrary} "$XDG_DATA_HOME/nvim/site/pack/core/opt/codesnap.nvim/lua/libs/linux-x86_64_generator.so"
      echo '${codesnapVersion}' > "$XDG_DATA_HOME/nvim/site/pack/core/opt/codesnap.nvim/lua/libs/.version"

      # Parser fixtures keep this sandboxed startup test offline.
      # A clean runtime test separately exercises upstream parser downloads and cc.
      ${lib.concatMapStringsSep "\n" (grammar: ''
          cp ${grammar}/parser "$XDG_DATA_HOME/nvim/site/parser/${grammar.language}.so"
        '')
        parserFixtures}
      cp -R ${pluginSources.nvim-treesitter}/runtime/queries "$XDG_DATA_HOME/nvim/site/queries"

      PATH="${cfg.finalPackage}/bin" nvim --headless --cmd 'lua vim.g.dotfiles_smoke_errors = {}; local notify = vim.notify; vim.notify = function(msg, level, opts) if level == vim.log.levels.ERROR then vim.g.dotfiles_smoke_errors = vim.list_extend(vim.g.dotfiles_smoke_errors, { tostring(msg) }) end; return notify(msg, level, opts) end' \
        -c 'lua dofile("${./neovim-smoke.lua}")' > startup.log 2>&1 || { cat startup.log; exit 1; }
      cat startup.log
      cmp ${configDir}/nvim-pack-lock.json "$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json"
      touch "$out"
    '';

  neovim-lua-lint =
    pkgs.runCommand "neovim-lua-lint" {
      nativeBuildInputs = [pkgs.stylua pkgs.luaPackages.luacheck pkgs.shellcheck];
    } ''
      set -euo pipefail
      export HOME=$TMPDIR
      stylua --config-path ${../.stylua.toml} --check ${configDir} ${./neovim-smoke.lua}
      luacheck --config ${../.luacheckrc} --no-cache ${configDir} ${./neovim-smoke.lua}
      shellcheck ${../scripts/check-neovim-runtime.sh} ${../scripts/check-lua.sh}
      touch "$out"
    '';
}
