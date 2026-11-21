.DEFAULT_GOAL := help
# Install packages before linking, even with make -j.
.NOTPARALLEL:
# Stow refuses conflicts and never overwrites files, so link is safe to repeat.
STOW_FLAGS ?=

APT_PACKAGES := \
	bemenu \
	gammastep \
	grim \
	kanshi \
	mako-notifier \
	network-manager-gnome \
	pass \
	pass-extension-otp \
	pulseaudio-utils \
	slurp \
	sway \
	swayidle \
	swaylock \
	waybar \
	wl-clipboard \
	wtype

DOCKER_BUILD_FLAGS ?=
POMO_MODULE := github.com/Jakub3628800/pomo/cmd/pomo@latest

.PHONY: install packages link clean test test-bootstrap pomo help

install: packages link

packages:
	@sudo apt-get update
	@sudo apt-get install --no-install-recommends -y $(APT_PACKAGES)

# Install or update pomo from its repository into ~/.local/bin, where the
# systemd unit and the waybar module expect it, then restart its daemon.
# Needs Go and a C compiler: CGO_ENABLED=1 makes a missing compiler fail the
# build instead of producing a binary without SQLite. A symlink left there by
# the old stowed bash script is removed first, so go install can't write
# through it.
pomo: link
	@command -v go >/dev/null || { echo "pomo needs Go. Install the golang-go package." >&2; exit 1; }
	@if [ -L "$(HOME)/.local/bin/pomo" ]; then rm "$(HOME)/.local/bin/pomo"; fi
	@CGO_ENABLED=1 GOBIN="$(HOME)/.local/bin" go install $(POMO_MODULE)
	@systemctl --user daemon-reload
	@systemctl --user enable pomo.service
	@systemctl --user restart pomo.service

link:
	@stow -R -v -d . -t "$(HOME)" --no-folding $(STOW_FLAGS) home

clean:
	@stow -D -v -d . -t "$(HOME)" --no-folding home

test:
	@set -e; tmp_home=$$(mktemp -d); \
		trap 'rm -rf "$$tmp_home"' 0 1 2 15; \
		stow -R -d . -t "$$tmp_home" --no-folding home; \
		HOME="$$tmp_home" sway --validate --config "$$tmp_home/.config/sway/config"
	@python3 -m json.tool home/.config/waybar/config >/dev/null
	@set -e; for script in home/.local/bin/*; do \
		case "$$(head -n 1 "$$script")" in \
		*bash*) bash -n "$$script" ;; \
		*) sh -n "$$script" ;; \
		esac; \
	done

test-bootstrap:
	@docker build $(DOCKER_BUILD_FLAGS) -t desktop-dotfiles-test .

help:
	@echo "Desktop targets: install packages link clean test test-bootstrap pomo"
