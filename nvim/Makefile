# Install Neovim before linking, even with make -j.
.NOTPARALLEL:

STOW_FLAGS ?=
NVIM ?= /opt/nvim-linux64/bin/nvim

.PHONY: install update upgrade clean help stow unstow test prepare-test install-nvim

install: install-nvim stow

update: stow

upgrade: install-nvim stow

clean: unstow

# Explicit network-dependent setup, kept out of normal fast checks.
prepare-test:
	@sh ./run-test.sh "$(NVIM)" prepare

test:
	@echo "Loading the Neovim configuration in an isolated temporary home..."
	@sh ./run-test.sh "$(NVIM)" check

stow:
	@stow -R -v -d . -t $(HOME) --no-folding $(STOW_FLAGS) home

unstow:
	@stow -v -D -d . -t $(HOME) --no-folding home

install-nvim:
	@./install-nvim.sh

help:
	@echo "Neovim targets: install update upgrade stow unstow prepare-test test clean"
