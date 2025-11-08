# ============================ CONFIGURATION =============================
# APT packages for desktop environment
APT_PACKAGES := bemenu xclip xdotool pass pass-extension-otp sway kanshi wtype mako-notifier gammastep swaylock

# ============================ PHONY TARGETS =============================
.PHONY: install update clean test stow unstow
.PHONY: apt-packages-install apt-packages-update

# ============================ MAIN TARGETS ==============================

install: apt-packages-install stow
	@echo "Desktop environment installation complete!"

update: apt-packages-update
	@echo "Desktop packages updated!"

clean:
	@echo "Unstowing desktop dotfiles..."
	@stow -v -D -d . -t $(HOME) --no-folding home

test:
	@echo "Building Docker image for testing..."
	@docker build -t desktop-dotfiles-test .
	@echo "Test build completed successfully!"

stow:
	@echo "Stowing desktop dotfiles..."
	@stow -v -d . -t $(HOME) --no-folding home

unstow:
	@echo "Unstowing desktop dotfiles..."
	@stow -v -D -d . -t $(HOME) --no-folding home

# ============================ APT PACKAGES ==============================

apt-packages-install:
	@echo "Installing desktop APT packages..."
	@sudo apt-get update
	@sudo apt-get install -y $(APT_PACKAGES)

apt-packages-update:
	@sudo apt-get update
	@sudo apt-get upgrade -y

# ============================ HELP ====================================

help:
	@echo "Desktop environment installation targets:"
	@echo "  make install        - Install everything (apt packages + stow dotfiles)"
	@echo "  make apt-packages-install - Install APT packages only"
	@echo "  make apt-packages-update  - Update APT packages"
	@echo "  make stow           - Symlink desktop dotfiles"
	@echo "  make unstow         - Remove desktop dotfile symlinks"
	@echo "  make update         - Update all packages"
	@echo "  make test           - Build Docker image for testing"
	@echo "  make clean          - Unstow dotfiles"
