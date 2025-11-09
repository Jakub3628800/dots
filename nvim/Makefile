# ============================ CONFIGURATION =============================
HOME_DIR := $(shell echo $$HOME)
STOW_FLAGS ?=

# ============================ PHONY TARGETS =============================
.PHONY: install update clean help stow unstow

# ============================ MAIN TARGETS ==============================

install: install-nvim stow

update: update-nvim

clean: unstow
	@echo "Cleaning build artifacts..."
	@rm -rf result

stow:
	@echo "Stowing Neovim dotfiles..."
	@stow -v -d . -t $(HOME_DIR) --no-folding $(STOW_FLAGS) home

unstow:
	@echo "Unstowing Neovim dotfiles..."
	@stow -v -D -d . -t $(HOME_DIR) home

# ============================ NVIM MANAGEMENT ============================

install-nvim:
	@echo "Installing Neovim binary..."
	@bash install-nvim.sh

update-nvim:
	@echo "Updating Neovim binary..."
	@bash install-nvim.sh --force

# ============================ HELP ======================================

help:
	@echo "Neovim installation system"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Main targets:"
	@echo "  make install        - Download Neovim binary and stow dotfiles"
	@echo "  make update         - Update Neovim binary"
	@echo "  make stow           - Symlink Neovim dotfiles"
	@echo "  make unstow         - Remove Neovim dotfile symlinks"
	@echo "  make clean          - Clean artifacts and unstow"
	@echo ""
	@echo "Neovim management:"
	@echo "  make install-nvim   - Download and install Neovim binary"
	@echo "  make update-nvim    - Update Neovim binary"
