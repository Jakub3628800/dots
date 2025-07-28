# Root Makefile - delegates to package-specific Makefiles

.PHONY: all
all: core desktop

.PHONY: core
core:
	@echo "\n=== Installing core packages ==="
	@$(MAKE) -C core install

.PHONY: desktop
desktop:
	@echo "\n=== Installing desktop environment ==="
	@$(MAKE) -C desktop install

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
	@echo "  make all        - Install everything (core + desktop)"
	@echo "  make core       - Install core packages only (server-compatible)"
	@echo "  make desktop    - Install desktop environment only"
	@echo "  make clean      - Unstow all dotfiles"
	@echo ""
	@echo "For package-specific options, use:"
	@echo "  make -C core help"
	@echo "  make -C desktop help"
