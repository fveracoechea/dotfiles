{
  lib,
  config,
  pkgs,
  dotfilesPkgs,
  ...
}: {
  options.dotfiles.neovim = {
    enable = lib.mkEnableOption "Neovim config";
    pluginLockPath = lib.mkOption {
      type = lib.types.nullOr (lib.types.strMatching "/.*");
      default = null;
      description = "Absolute path to a tracked writable plugin lockfile. Null seeds an independent writable lockfile once.";
    };
  };

  config = lib.mkIf config.dotfiles.neovim.enable {
    xdg.configFile = {
      "nvim/init.lua".source = ../../config/nvim/init.lua;
      "nvim/lua" = {
        source = ../../config/nvim/lua;
        recursive = true;
      };
      "nvim/lsp" = {
        source = ../../config/nvim/lsp;
        recursive = true;
      };
      "nvim/snippets" = {
        source = ../../config/nvim/snippets;
        recursive = true;
      };
      "nvim/nvim-pack-lock.json" = lib.mkIf (config.dotfiles.neovim.pluginLockPath != null) {
        source = config.lib.file.mkOutOfStoreSymlink config.dotfiles.neovim.pluginLockPath;
      };
    };

    home.activation.neovimPluginLock = lib.mkIf (config.dotfiles.neovim.pluginLockPath == null) (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        run ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg "${config.xdg.configHome}/nvim"}
        if [ ! -e ${lib.escapeShellArg "${config.xdg.configHome}/nvim/nvim-pack-lock.json"} ] &&
           [ ! -L ${lib.escapeShellArg "${config.xdg.configHome}/nvim/nvim-pack-lock.json"} ]; then
          run ${pkgs.coreutils}/bin/install -m644 ${../../config/nvim/nvim-pack-lock.json} ${lib.escapeShellArg "${config.xdg.configHome}/nvim/nvim-pack-lock.json"}
        fi
      ''
    );

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withRuby = false;
      withPython3 = false;
      withNodeJs = false;
      withPerl = false;
      extraWrapperArgs = ["--prefix" "PATH" ":" (lib.makeBinPath config.programs.neovim.extraPackages)];

      extraPackages = with pkgs; [
        alejandra
        biome
        black
        curl
        fd
        fzf
        gcc
        gh
        git
        gnutar
        gzip
        graphql-language-service-cli
        imagemagick
        isort
        lazygit
        lua-language-server
        nixd
        oxfmt
        oxlint
        prettier
        ripgrep
        stylelint
        stylua
        tailwindcss-language-server
        tree-sitter
        typescript
        unzip
        vscode-langservers-extracted
        wl-clipboard
        xclip
        dotfilesPkgs.stylelint-language-server
      ];
    };
  };
}
