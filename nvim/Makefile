STOW_FLAGS ?=

.PHONY: install update upgrade clean help stow unstow test install-nvim

install: install-nvim stow

update: stow

upgrade: install-nvim stow

clean: unstow

test:
	@echo "Checking Neovim installation..."
	@if [ -x "/opt/nvim-linux64/bin/nvim" ]; then \
		/opt/nvim-linux64/bin/nvim --version | head -n 1; \
	else \
		echo "Neovim not installed"; \
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
