# Default target
.PHONY: all
all: core-all desktop-apt stow-desktop install-nix nix-flake-install

HOME_DIR := $(shell echo $$HOME)
DESKTOP_APT_PACKAGES := \
    	xclip \
    	xcompmgr \
    	nitrogen \
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
	picom

# Install core packages and dotfiles
.PHONY: core-all
core-all:
	@echo "\nInstalling core packages and dotfiles..."
	@$(MAKE) -C core install

# Install only core (server-compatible) components
.PHONY: core
core: core-all

.PHONY: desktop-apt
desktop-apt:
	@echo "\nInstalling desktop APT packages..."
	@sudo apt-get install -y $(DESKTOP_APT_PACKAGES)

.PHONY: stow-desktop
stow-desktop:
	@echo "\nStowing desktop-env dotfiles..."
	@stow --target=$(HOME_DIR) desktop-env --no-folding

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
