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

    cmp-mini-snippets = pkgs.vimUtils.buildVimPlugin {
      name = "cmp_mini_snippets";
      src = pkgs.fetchFromGitHub {
        owner = "abeldekat";
        repo = "cmp-mini-snippets";
        rev = "582aea215ce2e65b880e0d23585c20863fbb7604";
        hash = "sha256-gSvhxrjz6PZBgqbb4eBAwWEWSdefM4qL3nb75qGPaFA=";
      };
      nvimRequireCheck = "cmp_mini_snippets";
      dependencies = [pkgs.vimPlugins.nvim-cmp];
    };
  in
    lib.mkIf config.dotfiles.neovim.enable {
      xdg = {
        enable = lib.mkDefault true;
        configFile."config" = {
          recursive = true;
          source = ../nvim;
        };
      };

      home.packages = global-packages;

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        initLua = lib.mkBefore (lib.fileContents ../nvim/init.lua);

        extraPackages = with pkgs;
          lib.optionals pkgs.stdenv.isLinux [
            xclip
            wl-clipboard
          ]
          ++ [
            nixd
            stylelint-lsp
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
          nvim-cmp
          cmp-path
          cmp-buffer
          cmp-nvim-lsp
          cmp-mini-snippets
          copilot-lua
          copilot-cmp
          vim-tmux-navigator
          nvim-ts-context-commentstring
          nvim-ts-autotag
          nvim-lsp-file-operations
          trouble-nvim
          mini-nvim
          snacks-nvim
          yazi-nvim
          catppuccin-nvim
          nvim-lspconfig
          tailwind-tools-nvim
          conform-nvim
          nvim-lint
          gitsigns-nvim
          codesnap-nvim
          opencode-nvim
        ];
      };
    };
}
