macos-install:
	brew install jesseduffield/lazygit/lazygit
	brew install lazygit tmux neovim ripgrep volta gh
	brew install --cask alacritty
	brew tap homebrew/cask-fonts
	brew install --cask font-jetbrains-mono-nerd-font
	brew install --cask font-sauce-code-pro-nerd-font
ubuntu-install:
	sudo snap refresh
	sudo snap install nvim --classic
	sudp apt update
	sudo add-apt-repository ppa:aslatter/ppa -y
	sudo apt install stow zsh tmux alacritty ripgrep curl
	curl https://get.volta.sh | bash


