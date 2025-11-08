# Root Makefile - delegates to package-specific Makefiles

.PHONY: install
install: install-core install-desktop install-nvim

.PHONY: update
update: update-core update-desktop update-nvim

.PHONY: test
test: test-core test-desktop

.PHONY: install-core
install-core:
	@echo "\n=== Installing core packages ==="
	@$(MAKE) -C core install

.PHONY: update-core
update-core:
	@echo "\n=== Updating core packages ==="
	@$(MAKE) -C core update

.PHONY: install-desktop
install-desktop:
	@echo "\n=== Installing desktop environment ==="
	@$(MAKE) -C desktop install

.PHONY: update-desktop
update-desktop:
	@echo "\n=== Updating desktop packages ==="
	@$(MAKE) -C desktop update

.PHONY: install-nvim
install-nvim:
	@echo "\n=== Installing Neovim ==="
	@$(MAKE) -C nvim install

.PHONY: update-nvim
update-nvim:
	@echo "\n=== Updating Neovim ==="
	@$(MAKE) -C nvim update

.PHONY: test-core
test-core:
	@echo "\n=== Testing core packages ==="
	@$(MAKE) -C core test

.PHONY: test-desktop
test-desktop:
	@echo "\n=== Testing desktop environment ==="
	@$(MAKE) -C desktop test

.PHONY: clean
clean:
	@echo "\n=== Cleaning all packages ==="
	@$(MAKE) -C core unstow
	@$(MAKE) -C desktop unstow
	@$(MAKE) -C nvim unstow

.PHONY: help
help:
	@echo "Dotfiles installation system"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Main targets:"
	@echo "  make install        - Install everything (core + desktop + nvim)"
	@echo "  make update         - Update everything (core + desktop + nvim)"
	@echo "  make test           - Test everything (core + desktop + nvim)"
	@echo "  make install-core   - Install core packages only"
	@echo "  make update-core    - Update core packages only"
	@echo "  make test-core      - Test core packages only"
	@echo "  make install-desktop - Install desktop environment only"
	@echo "  make update-desktop  - Update desktop packages only"
	@echo "  make test-desktop   - Test desktop environment only"
	@echo "  make install-nvim   - Install Neovim only"
	@echo "  make update-nvim    - Update Neovim only"
	@echo "  make clean          - Unstow all dotfiles"
	@echo ""
	@echo "For package-specific options, use:"
	@echo "  make -C core help"
	@echo "  make -C desktop help"
	@echo "  make -C nvim help"
