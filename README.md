# 💻 Development Environment Configuration

These dotfiles provide a consistent and optimized experience across different MacOS and Linux devices.

https://github.com/user-attachments/assets/d0bfe629-405e-45f3-b25b-0b6af091a902




## Main Features:

- Keyboard Focused
- Minimal Distractions
- Configuration as Code
- Highly Customizable
- Git submodules

## Tooling:

- [Kitty](https://sw.kovidgoyal.net/kitty/): Cross-platform, fast, feature-rich, GPU based terminal.
- [TMUX](https://github.com/tmux/tmux): Terminal Multiplexer.
- [LazyGit](https://github.com/jesseduffield/lazygit): A simple terminal UI for git commands.
- [ZSH](https://zsh.sourceforge.io/)
  - [Zinit](https://github.com/zdharma-continuum/zinit): Flexible and fast ZSH plugin manager.
  - [Oh My Posh](https://ohmyposh.dev/): Customisable and low-latency cross platform/shell prompt renderer.
- [Neovim](https://neovim.io/)
  - [lazy.nvim](https://github.com/folke/lazy.nvim): A modern plugin manager for Neovim.
  - [catppuccin](https://github.com/catppuccin/nvim): Soothing pastel theme for Neovim.

## Installation

1. Run:

```zsh
git clone --recurse-submodules git@github.com:fveracoechea/dotfiles.git ~/.config
cd ~/config
make brew-install
```

2. Add the following at the top of your `.zshrc`:

```zsh
source ~/.config/zsh/oh-my-zsh.zsh
```

3. Then open `tmux` and press `prefix` + <kbd>I</kbd> (capital i, as in **I**nstall) to fetch the plugin.

4. I manage the various configuration files in this repo using [GNU Stow](https://www.gnu.org/software/stow/). This allows me to set up symlinks for all of my dotfiles using a single command:

```.zsh
stow .
```

You're good to go!

