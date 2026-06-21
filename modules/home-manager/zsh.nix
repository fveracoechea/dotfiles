{
  lib,
  config,
  pkgs,
  ...
}: {
  options.dotfiles.zsh.enable = lib.mkEnableOption "zsh shell";

  config = lib.mkIf config.dotfiles.zsh.enable {
    home.packages = with pkgs; [
      fastfetch
    ];

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.eza = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      autosuggestion.enable = true;

      history = {
        ignoreAllDups = true;
        ignoreDups = true;
        ignoreSpace = true;
        share = true;
        size = 5000;
      };

      shellAliases = {
        t = ''tmux new-session -A -s "$(basename "$PWD")"'';
        ls = "eza";
        la = "eza -abghHl --no-user --icons";
        cd = "z";
        cat = "bat";
        e = "exit";
        c = "clear";
      };

      plugins = [
        {
          name = "zsh-fzf-history-search";
          # nurl https://github.com/joshskidmore/zsh-fzf-history-search
          src = pkgs.fetchFromGitHub {
            owner = "joshskidmore";
            repo = "zsh-fzf-history-search";
            rev = "d5a9730b5b4cb0b39959f7f1044f9c52743832ba";
            hash = "sha256-tQqIlkgIWPEdomofPlmWNEz/oNFA1qasILk4R5RWobY=";
          };
        }
        {
          name = "fzf-tab";
          # nurl https://github.com/Aloxaf/fzf-tab
          src = pkgs.fetchFromGitHub {
            owner = "Aloxaf";
            repo = "fzf-tab";
            rev = "b6e1b22458a131f835c6fe65bdb88eb45093d2d2";
            hash = "sha256-4A7zpaO1rNPvS0rrmmxg56rJGpZHnw/g+x5FJd0EshI=";
          };
        }
      ];

      initContent =
        # sh
        ''
          export SHELL=$(which zsh)

          # Completion styling
          zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
          zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
          zstyle ':completion:*' menu no
          zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
          zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

          # Source secrets
          source ~/.config/zsh/secrets.zsh

          # Make sure brew is on the path for M1
          if [[ $(uname -m) == 'arm64' ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
          fi

          # startup script
          clear
        '';
    };
  };
}
