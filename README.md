## Installation

### NeoVim
```zsh
brew install neovim
brew install ripgrep
```

### Alacritty
```zsh
brew install --cask alacritty
git clone https://github.com/catppuccin/alacritty.git ~/.config/alacritty/catppuccin
```

### oh my zsh
```zsh
ZSH="$HOME/.config/oh-my-zsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

then add the following at the top of your `~/.zshrc`:
```zsh
source ~/.config/zsh/oh-my-zsh.conf
```

### tmux
```zsh
brew install tmux 
```

### Nerd Fonts
```zsh
brew tap homebrew/cask-fonts
brew install font-hack-nerd-font
```

### Volta

```zsh
brew install volta
```