{
  lib,
  config,
  pkgs,
  dotfilesPkgs,
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

    stylelint-language-server = dotfilesPkgs.stylelint-language-server;
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
