STOW_FLAGS ?=
NVIM ?= /opt/nvim-linux64/bin/nvim

.PHONY: install update upgrade clean help stow unstow test install-nvim

install: install-nvim stow

update: stow

upgrade: install-nvim stow

clean: unstow

test:
	@echo "Loading the Neovim configuration..."
	@if [ -x "$(NVIM)" ]; then \
		XDG_CONFIG_HOME="$(CURDIR)/home/.config" NVIM_APPNAME=nvim \
			"$(NVIM)" --headless -i NONE -u NONE -l test-config.lua; \
	else \
		echo "Neovim not installed at $(NVIM)"; \
		exit 1; \
	fi

stow:
	@stow -R -v -d . -t $(HOME) --no-folding $(STOW_FLAGS) home

unstow:
	@stow -v -D -d . -t $(HOME) --no-folding home

install-nvim:
	@./install-nvim.sh

help:
	@echo "Neovim targets: install update upgrade stow unstow test clean"
