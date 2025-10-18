# ============================ CONFIGURATION =============================
HOME_DIR := $(shell echo $$HOME)
STOW_FLAGS ?=

# ============================ PHONY TARGETS =============================
.PHONY: install update clean help stow unstow
.PHONY: install-nix install-flake remove-flake update-flake

# ============================ MAIN TARGETS ==============================

install: install-flake stow

update: update-flake

clean: unstow
	@echo "Cleaning build artifacts..."
	@rm -rf result

stow:
	@echo "Stowing Neovim dotfiles..."
	@stow -v -d . -t $(HOME_DIR) --no-folding $(STOW_FLAGS) home

unstow:
	@echo "Unstowing Neovim dotfiles..."
	@stow -v -D -d . -t $(HOME_DIR) home

# ============================ FLAKE MANAGEMENT ==========================

install-nix:
	@if command -v nix >/dev/null 2>&1; then \
		echo "Nix is already installed."; \
	else \
		echo "Installing Nix via Determinate Systems..."; \
		curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install; \
	fi

install-flake: install-nix
	@echo "Installing Neovim from flake..."
	@nix profile install .#neovim

remove-flake:
	@echo "Removing Neovim from nix profile..."
	@nix profile remove nvim

update-flake: install-nix
	@echo "Updating flake lock..."
	@nix flake update --flake .
	@echo "Upgrading Neovim installation..."
	@nix profile upgrade nvim

# ============================ HELP ======================================

help:
	@echo "Neovim installation system"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Main targets:"
	@echo "  make install        - Install Neovim from flake and stow dotfiles"
	@echo "  make update         - Update flake lock and upgrade Neovim"
	@echo "  make stow           - Symlink Neovim dotfiles"
	@echo "  make unstow         - Remove Neovim dotfile symlinks"
	@echo "  make clean          - Clean artifacts and unstow"
	@echo ""
	@echo "Flake management:"
	@echo "  make install-flake  - Install Neovim from flake"
	@echo "  make remove-flake   - Remove Neovim from nix profile"
	@echo "  make update-flake   - Update flake and upgrade Neovim"
