{
  lib,
  config,
  pkgs,
  ...
}: {
  options.dotfiles.neovim.enable = lib.mkEnableOption "Neovim config";

  imports = [
    ./snippets.nix
  ];

  config = let
    global-packages = with pkgs; [
      nixd
      alejandra
      graphql-language-service-cli
      stylelint
      fzf
      tree-sitter
    ];

    # Official @stylelint/language-server (not packaged in nixpkgs; the
    # `stylelint-lsp` attr is bmatcuk's separate project with a different API).
    stylelint-language-server = pkgs.buildNpmPackage {
      pname = "stylelint-language-server";
      version = "1.1.1";
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@stylelint/language-server/-/language-server-1.1.1.tgz";
        hash = "sha256-l+7GKyWhrEvJ3boylbQBAZziwzbZoQdxWi9np5vaTf4=";
      };
      postPatch = ''
        cp ${./stylelint-language-server-lock.json} package-lock.json
      '';
      npmDepsHash = "sha256-yMn596qq+PtYiaSCrUl05mQu3Zyl51a7d7S4GkuKjzY=";
      dontNpmBuild = true;
    };
  in
    lib.mkIf config.dotfiles.neovim.enable {
      xdg = {
        enable = lib.mkDefault true;

        configFile."nvim/lua" = {
          recursive = true;
          source = ./config/lua;
        };
        configFile."nvim/lsp" = {
          recursive = true;
          source = ./config/lsp;
        };
      };

      home.packages = global-packages;

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        withRuby = true;
        withPython3 = true;
        initLua = lib.mkBefore (lib.fileContents ./config/init.lua);

        extraPackages = with pkgs;
          lib.optionals pkgs.stdenv.isLinux [
            xclip
            wl-clipboard
          ]
          ++ [
            nixd
            stylelint-language-server
            biome
            lua-language-server
            deno
            typescript
            typescript-language-server
            vscode-langservers-extracted
            tailwindcss-language-server
            nginx-language-server
            bash-language-server
            stylua
            shfmt
            eslint_d

            nixd
            alejandra
            graphql-language-service-cli
            stylelint
            fzf
            tree-sitter
          ]
          ++ global-packages;

        plugins = with pkgs.vimPlugins; [
          nvim-treesitter.withAllGrammars
          todo-comments-nvim
          plenary-nvim
          nui-nvim
          lualine-nvim
          vim-tmux-navigator
          nvim-ts-context-commentstring
          nvim-ts-autotag
          nvim-lsp-file-operations
          mini-nvim
          bufferline-nvim
          snacks-nvim
          catppuccin-nvim
          nvim-lspconfig
          conform-nvim
          gitsigns-nvim
          codesnap-nvim
          opencode-nvim
        ];
      };
    };
}
