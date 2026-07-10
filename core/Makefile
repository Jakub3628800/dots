APT_PACKAGES := \
	build-essential \
	ca-certificates \
	curl \
	direnv \
	entr \
	fzf \
	gh \
	git \
	gnupg2 \
	jq \
	nodejs \
	openssh-client \
	ripgrep \
	rustup \
	stow \
	tig \
	tmux \
	unzip \
	vim \
	zsh

CARGO_PACKAGES := git-delta prek starship uv

.PHONY: install update upgrade packages apt-update apt-packages rust-toolchain
.PHONY: cargo-packages stow unstow system-upgrade test help

install: packages stow

# Configuration refreshes should stay cheap. Use `make upgrade` for packages.
update: stow

upgrade: packages stow

packages: apt-packages cargo-packages

apt-update:
	@sudo apt-get update

apt-packages: apt-update
	@sudo apt-get install --no-install-recommends -y $(APT_PACKAGES)

rust-toolchain: apt-packages
	@rustup default stable

cargo-packages: rust-toolchain
	@if [ -f $$HOME/.cargo/env ]; then . $$HOME/.cargo/env; fi; \
		for pkg in $(CARGO_PACKAGES); do \
			echo "Reconciling $$pkg..."; \
			cargo install "$$pkg" --locked; \
		done

stow:
	@stow -R -v -d . -t $(HOME) --no-folding home

unstow:
	@stow -v -D -d . -t $(HOME) --no-folding home

system-upgrade: apt-update
	@sudo apt-get upgrade -y

test:
	@docker build -t core-dotfiles-test .

help:
	@grep -hE '^[a-zA-Z0-9][a-zA-Z0-9_.-]*:([^=]|$$)' $(MAKEFILE_LIST) | cut -d: -f1 | sort -u
