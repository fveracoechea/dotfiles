# 💻 Development Environment Config

This repository contains my dotfile configuration.

These dotfiles provide a seamless and uniform development experience across different MacOS devices.
It guarantees a consistent and optimized environment tailored to my preferences and workflow.

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

```zsh
git clone --recurse-submodules git@github.com:fveracoechea/dotfiles.git ~/.config
cd ~/config
make brew-install
```

Then open `tmux` and press `prefix` + <kbd>I</kbd> (capital i, as in **I**nstall) to fetch the plugin.

You're good to go!
