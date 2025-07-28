# Desktop environment Makefile
.PHONY: all
all: apt stow nix-flake-install

HOME_DIR := $(shell echo $$HOME)
STOW_FLAGS ?=

.PHONY: apt
apt:
	@echo "\nInstalling desktop APT packages..."
	@xargs -r -a apt-packages.txt sudo apt-get install -y

.PHONY: stow
stow:
	@echo "\nStowing desktop dotfiles..."
	@stow -v -d . -t $(HOME_DIR) --no-folding $(STOW_FLAGS) home

.PHONY: unstow
unstow:
	@echo "\nUnstowing desktop dotfiles..."
	@stow -v -D -d . -t $(HOME_DIR) home

.PHONY: install-nix
install-nix:
	@if command -v nix >/dev/null 2>&1; then \
		echo "Nix is already installed."; \
	else \
		echo "Installing Nix..."; \
		curl -L https://nixos.org/nix/install | sh -s -- ; \
	fi

.PHONY: nix-flake-install
nix-flake-install: install-nix
	@echo "\nInstalling nix flake to profile..."
	@nix profile install .
	@nix flake update --flake .

.PHONY: nix-flake-remove
nix-flake-remove:
	@echo "\nRemoving dots from nix profile..."
	@nix profile remove dots

.PHONY: install
install: all

.PHONY: update
update:
	@echo "\nUpdating desktop packages..."
	@sudo apt-get update
	@echo "Upgrading installed packages..."
	@sudo apt-get upgrade -y
	@echo "Updating nix flake..."
	@nix flake update --flake .

.PHONY: help
help:
	@echo "Desktop environment installation targets:"
	@echo "  make install        - Install everything (apt packages, stow dotfiles, nix flake)"
	@echo "  make apt            - Install desktop APT packages"
	@echo "  make stow           - Symlink desktop dotfiles"
	@echo "  make unstow         - Remove desktop dotfile symlinks"
	@echo "  make nix-flake-install - Install Nix flake packages"
	@echo "  make nix-flake-remove  - Remove Nix flake packages"
