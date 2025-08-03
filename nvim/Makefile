# Neovim Makefile
.PHONY: all
all: install-nix nix-flake-install stow

HOME_DIR := $(shell echo $$HOME)
STOW_FLAGS ?=

.PHONY: install-nix
install-nix:
	@if command -v nix >/dev/null 2>&1; then \
		echo "Nix is already installed."; \
	else \
		echo "Installing Nix..."; \
		curl -L https://nixos.org/nix/install | sh -s -- ; \
	fi

.PHONY: stow
stow:
	@echo "\nStowing Neovim dotfiles..."
	@stow -v -d . -t $(HOME_DIR) --no-folding $(STOW_FLAGS) home

.PHONY: unstow
unstow:
	@echo "\nUnstowing Neovim dotfiles..."
	@stow -v -D -d . -t $(HOME_DIR) home

.PHONY: nix-flake-install
nix-flake-install: install-nix
	@echo "\nInstalling Neovim to profile..."
	@nix profile install .#neovim
	@nix flake update --flake .

.PHONY: nix-flake-remove
nix-flake-remove:
	@echo "\nRemoving Neovim from nix profile..."
	@nix profile remove neovim

.PHONY: install
install: all

.PHONY: update
update:
	@echo "\nUpdating Neovim..."
	@echo "Updating nix flake..."
	@nix flake update --flake .
	@echo "Upgrading Neovim installation..."
	@nix profile upgrade neovim

.PHONY: clean
clean: unstow
	@echo "\nCleaning build artifacts..."
	@rm -rf result

.PHONY: help
help:
	@echo "Neovim installation targets:"
	@echo "  make install        - Install everything (Nix, Neovim, stow dotfiles)"
	@echo "  make stow           - Symlink Neovim dotfiles"
	@echo "  make unstow         - Remove Neovim dotfile symlinks"
	@echo "  make nix-flake-install - Install Neovim from Nix flake"
	@echo "  make nix-flake-remove  - Remove Neovim from Nix profile"
	@echo "  make update         - Update Neovim and flake lock"
	@echo "  make clean          - Clean artifacts and unstow"
