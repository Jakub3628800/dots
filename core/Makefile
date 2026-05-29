APT_PACKAGES := zsh vim tig gh stow curl unzip jq direnv tmux ripgrep fzf bat nodejs gnupg2 rustup
CARGO_PACKAGES := starship git-delta uv prek

.PHONY : install update

install: apt-packages-install cargo-install stow
update: apt-packages-update cargo-update stow


apt-update:
	@sudo apt-get update

apt-packages-install: apt-update
	@sudo apt-get install --no-install-recommends -y $(APT_PACKAGES)

apt-packages-update: apt-update
	@sudo apt-get install --only-upgrade -y $(APT_PACKAGES)

system-upgrade: apt-update
	@sudo apt-get upgrade -y


rust-toolchain: apt-packages-install
	rustup default stable

cargo-install: rust-toolchain
	@if [ -f $$HOME/.cargo/env ]; then . $$HOME/.cargo/env; fi; \
		for pkg in $(CARGO_PACKAGES); do \
			if ! command -v $$pkg >/dev/null 2>&1; then \
				echo "Installing $$pkg..."; \
				cargo install $$pkg --locked; \
			else \
				echo "$$pkg is already installed"; \
			fi; \
		done

cargo-update:
	@if [ -f $$HOME/.cargo/env ]; then . $$HOME/.cargo/env; fi; \
		for pkg in $(CARGO_PACKAGES); do \
			echo "Updating $$pkg..."; \
			cargo install $$pkg --locked --force; \
		done


stow:
	@stow -v -d . -t $(HOME) --no-folding home

unstow:
	@stow -v -D -d . -t $(HOME) --no-folding home


test:
	@docker build -t core-dotfiles-test .

help:
	@grep -hE '^[a-zA-Z0-9][a-zA-Z0-9_.-]*:([^=]|$$)' $(MAKEFILE_LIST) | cut -d: -f1 | sort -u
