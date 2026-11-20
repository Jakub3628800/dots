.DEFAULT_GOAL := help
# Install packages before linking, even with make -j.
.NOTPARALLEL:
# Stow refuses conflicts and never overwrites files, so link is safe to repeat.
STOW_FLAGS ?=

APT_PACKAGES := \
	build-essential \
	ca-certificates \
	curl \
	direnv \
	fzf \
	gh \
	git \
	jq \
	nodejs \
	openssh-client \
	ripgrep \
	rustup \
	stow \
	tmux \
	unzip \
	vim \
	zsh

CARGO_PACKAGES := git-delta prek@0.5.11 starship uv@0.13.8
DOCKER_BUILD_FLAGS ?=

.PHONY: install packages link clean apt-update apt-packages rust-toolchain
.PHONY: cargo-packages system-upgrade test test-bootstrap help

install: packages link

packages: apt-packages cargo-packages

apt-update:
	@sudo apt-get update

apt-packages: apt-update
	@sudo apt-get install --no-install-recommends -y $(APT_PACKAGES)

# Refresh existing toolchains too: the pinned uv and prek require Rust 1.97+.
rust-toolchain: apt-packages
	@rustup update stable --no-self-update
	@rustup default stable

cargo-packages: rust-toolchain
	@set -e; \
		if [ -f $$HOME/.cargo/env ]; then . $$HOME/.cargo/env; fi; \
		for pkg in $(CARGO_PACKAGES); do \
			echo "Reconciling $$pkg..."; \
			cargo install "$$pkg" --locked; \
		done

link:
	@stow -R -v -d . -t "$(HOME)" --no-folding $(STOW_FLAGS) home

clean:
	@stow -D -v -d . -t "$(HOME)" --no-folding home

system-upgrade: apt-update
	@sudo apt-get upgrade -y

test:
	@bash -n home/.local/bin/cmd-picker
	@zsh -n home/.zshrc
	@set -e; tmp_home=$$(mktemp -d); \
		trap 'rm -rf "$$tmp_home"' 0 1 2 15; \
		touch "$$tmp_home/.profile"; \
		stow -R -d . -t "$$tmp_home" --no-folding home; \
		test -L "$$tmp_home/.zshrc"; \
		test -f "$$tmp_home/.profile"

test-bootstrap:
	@docker build $(DOCKER_BUILD_FLAGS) -t core-dotfiles-test .

help:
	@grep -hE '^[a-zA-Z0-9][a-zA-Z0-9_.-]*:([^=]|$$)' $(MAKEFILE_LIST) | cut -d: -f1 | sort -u
