{
  lib,
  config,
  pkgs,
  dotfilesPkgs,
  ...
}: {
  options.dotfiles.neovim.enable = lib.mkEnableOption "Neovim config";

  config = let
    global-packages = with pkgs; [
      alejandra
      graphql-language-service-cli
      stylelint
      fzf
      tree-sitter
    ];

    stylelint-language-server = dotfilesPkgs.stylelint-language-server;
  in
    lib.mkIf config.dotfiles.neovim.enable {
      home.packages = global-packages;

      xdg.configFile."nvim" = {
        recursive = true;
        source = ../../config/nvim;
      };

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        withRuby = false;
        withPython3 = false;
        initLua = lib.mkBefore (lib.fileContents ../../config/nvim/init.lua);

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
