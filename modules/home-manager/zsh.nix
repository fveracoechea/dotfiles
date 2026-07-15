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
      jq
      just
      ripgrep
      wget
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
        ".." = "cd ..";
        cc = "claude --dangerously-skip-permissions";
      };

      plugins = [
        {
          name = "vi-mode";
          src = pkgs.zsh-vi-mode;
          file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
        }
        {
          name = "zsh-fzf-history-search";
          src = pkgs.zsh-fzf-history-search;
          file = "share/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh";
        }
        {
          name = "fzf-tab";
          src = pkgs.zsh-fzf-tab;
          file = "share/fzf-tab/fzf-tab.plugin.zsh";
        }
        {
          name = "pure-prompt";
          src = pkgs.pure-prompt;
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

          # Rebind ^R after vi-mode init so fzf-history-search wins
          function zvm_after_init() {
            bindkey '^R' fzf_history_search
          }

          bindkey '^f' autosuggest-accept

          # Source secrets
          source ~/.config/zsh/secrets.zsh

          autoload -U promptinit; promptinit
          prompt pure

          zstyle :prompt:pure:git:stash show yes
          zstyle :prompt:pure:path:separator dim yes
        '';
    };
  };
}
