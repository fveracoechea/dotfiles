
# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Run oh-my-posh
eval "$(oh-my-posh init zsh --config $XDG_CONFIG_HOME/zsh/catppuccin.json)"

# Adds volta to the path
PATH="$VOLTA_HOME/bin:$PATH"
