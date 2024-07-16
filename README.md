# 💻 Development Environment Config

This repository contains my dotfile configuration.

These dotfiles provide a seamless and uniform development experience across different MacOS devices.
It guarantees a consistent and optimized environment tailored to my preferences and workflow.

![image](https://github.com/user-attachments/assets/1b153979-9d6d-4937-aa67-ca4c5e33dac9)
![image](https://github.com/user-attachments/assets/73f9ad70-955f-4e12-9187-613b95a9a628)



## Main Features:

- Keyboard Focused
- Minimal Distractions
- Configuration as Code
- Highly Customizable
- Git submodules

## Tooling:

- [Alacritty](https://alacritty.org): A cross-platform, OpenGL terminal emulator.
- [Oh My Zsh](https://ohmyz.sh): Community-driven framework for managing your Zsh configuration.
- [TMUX](https://github.com/tmux/tmux): Terminal Multiplexer.
- [NvChad](https://nvchad.com): Blazing fast Neovim config providing solid defaults and a beautiful UI.
- [lazygit](https://github.com/jesseduffield/lazygit): A simple terminal UI for git commands.

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
