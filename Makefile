# Default target
.PHONY: all
all: install-uv apt install-stow stow install-nix nix-flake-install

UV_EXISTS := $(shell command -v uv 2> /dev/null)
HOME_DIR := $(shell echo $$HOME)
APT_PACKAGES := \
	zsh \
    	bat \
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
	@echo "uv is already installed"
	@echo "Checking for uv update"
	uv self update
endif


.PHONY: apt
apt:
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
	@stow --target=$(HOME_DIR) core
	@stow --target=$(HOME_DIR) desktop-env

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
	@echo "Installing nix flake to profile..."
	@nix profile install .
	@nix flake update --flake .

.PHONY: nix-flake-remove
nix-flake-remove:
	@echo "Removing dots from nix profile..."
	@nix profile remove dots
