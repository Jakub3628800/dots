# Default target
.PHONY: all
all: install-uv apt install-stow stow install-nix nix-flake-install install-py-scripts

UV_EXISTS := $(shell command -v uv 2> /dev/null)
HOME_DIR := $(shell echo $$HOME)
APT_PACKAGES := \
	zsh \
    	bat \
	eza \
	fzf \
	curl \
	direnv \
    	vim \
    	xclip \
    	python3-virtualenv \
    	tig \
    	gh \
    	xcompmgr \
    	nitrogen \
    	zsh \
    	xdotool \
    	pass \
    	pass-extension-otp \
    	i3 \
    	sway \
	kanshi \
	wtype \
	mako-notifier \
	gammastep \
    	i3lock \
    	redshift \
    	swaylock \
    	stow \
	tmux \
    	ripgrep \
	picom

.PHONY: install-uv
install-uv:
ifndef UV_EXISTS
	@curl -LsSf https://astral.sh/uv/install.sh | sh
else
	@echo "\nuv is already installed"
	@echo "Checking for uv update"
	uv self update
endif


.PHONY: apt
apt:
	@echo "\nInstalling apt packages..."
	@sudo apt-get install -y $(APT_PACKAGES)

.PHONY: install-stow
install-stow:
	@if command -v stow >/dev/null 2>&1; then \
		echo "Stow is already installed."; \
	else \
		echo "Installing Stow..."; \
		sudo apt-get install -y stow; \
	fi

.PHONY: stow
stow: apt install-stow
	@echo "\nStowing dotfiles..."
	@stow --target=$(HOME_DIR) core
	@stow --target=$(HOME_DIR) desktop-env

.PHONY: install-py-scripts
install-py-scripts:
	@echo "\nInstalling Python scripts..."
	uv tool install git+https://github.com/Jakub3628800/py-scripts

.PHONY: install-nix
install-nix:
	@if command -v nix >/dev/null 2>&1; then \
		echo "Nix is already installed."; \
	else \
		echo "Installing Nix..."; \
		curl -L https://nixos.org/nix/install | sh -s -- ; \
	fi

.PHONY: nix-flake-install
nix-flake-install:
	@echo "\nInstalling nix flake to profile..."
	@nix profile install .
	@nix flake update --flake .

.PHONY: nix-flake-remove
nix-flake-remove:
	@echo "\nRemoving dots from nix profile..."
	@nix profile remove dots
