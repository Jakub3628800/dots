# Root Makefile - delegates to package-specific Makefiles

.PHONY: install
install: install-core install-desktop

.PHONY: update
update: update-core update-desktop

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

.PHONY: clean
clean:
	@echo "\n=== Cleaning all packages ==="
	@$(MAKE) -C core unstow
	@$(MAKE) -C desktop unstow

.PHONY: help
help:
	@echo "Dotfiles installation system"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Main targets:"
	@echo "  make install        - Install everything (core + desktop)"
	@echo "  make update         - Update everything (core + desktop)"
	@echo "  make install-core   - Install core packages only"
	@echo "  make update-core    - Update core packages only"
	@echo "  make install-desktop - Install desktop environment only"
	@echo "  make update-desktop  - Update desktop packages only"
	@echo "  make clean          - Unstow all dotfiles"
	@echo ""
	@echo "For package-specific options, use:"
	@echo "  make -C core help"
	@echo "  make -C desktop help"