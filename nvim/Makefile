.DEFAULT_GOAL := help
# Install Neovim before linking, even with make -j.
.NOTPARALLEL:
# Stow refuses conflicts and never overwrites files, so link is safe to repeat.
STOW_FLAGS ?=
NVIM ?= /opt/nvim-linux64/bin/nvim

.PHONY: install packages link clean help test prepare-test install-nvim

install: packages link

packages: install-nvim

# Explicit network-dependent setup, kept out of normal fast checks.
prepare-test:
	@sh ./run-test.sh "$(NVIM)" prepare

test:
	@echo "Loading the Neovim configuration in an isolated temporary home..."
	@sh ./run-test.sh "$(NVIM)" check

link:
	@stow -R -v -d . -t "$(HOME)" --no-folding $(STOW_FLAGS) home

clean:
	@stow -D -v -d . -t "$(HOME)" --no-folding home

install-nvim:
	@./install-nvim.sh

help:
	@echo "Neovim targets: install packages link clean prepare-test test install-nvim"
