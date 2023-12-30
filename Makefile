brew-install:
	brew install jesseduffield/lazygit/lazygit
	brew install lazygit tmux neovim ripgrep volta gh
	brew install --cask alacritty
	brew tap homebrew/cask-fonts
	brew install --cask font-jetbrains-mono-nerd-font
	brew install --cask font-sauce-code-pro-nerd-font
apt-install:
	sudo add-apt-repository ppa:aslatter/ppa -y
	sudo apt install zsh tmux alacritty neovim ripgrep curl
	curl https://get.volta.sh | bash


