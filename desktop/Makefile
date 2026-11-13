# Install packages before linking, even with make -j.
.NOTPARALLEL:

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

.PHONY: all install update upgrade packages stow unstow clean system-upgrade test test-bootstrap pomo help

# Keep `all` as a compatibility alias without depending on the active session.
all: install

install: packages stow
	@echo "Desktop environment installation complete!"

update: stow

upgrade: packages stow
	@echo "Desktop packages updated!"

packages:
	@sudo apt-get update
	@sudo apt-get install --no-install-recommends -y $(APT_PACKAGES)

stow:
	@stow -R -v -d . -t $(HOME) --no-folding home

unstow:
	@stow -v -D -d . -t $(HOME) --no-folding home

clean: unstow

# Install or update pomo from its repository into ~/.local/bin, where the
# systemd unit and the waybar module expect it, then restart its daemon.
# Needs Go and a C compiler: CGO_ENABLED=1 makes a missing compiler fail the
# build instead of producing a binary without SQLite. A symlink left there by
# the old stowed bash script is removed first, so go install can't write
# through it.
pomo: stow
	@command -v go >/dev/null || { echo "pomo needs Go: https://go.dev/dl/" >&2; exit 1; }
	@if [ -L "$(HOME)/.local/bin/pomo" ]; then rm "$(HOME)/.local/bin/pomo"; fi
	@CGO_ENABLED=1 GOBIN="$(HOME)/.local/bin" go install $(POMO_MODULE)
	@systemctl --user daemon-reload
	@systemctl --user enable pomo.service
	@systemctl --user restart pomo.service

system-upgrade:
	@sudo apt-get update
	@sudo apt-get upgrade -y

test:
	@set -e; tmp_home=$$(mktemp -d); \
		trap 'rm -rf "$$tmp_home"' 0 1 2 15; \
		stow -R -d . -t "$$tmp_home" --no-folding home; \
		HOME="$$tmp_home" sway --validate --config "$$tmp_home/.config/sway/config"
	@python3 -m json.tool home/.config/waybar/config >/dev/null
	@for script in home/.local/bin/*; do sh -n "$$script"; done

test-bootstrap:
	@docker build $(DOCKER_BUILD_FLAGS) -t desktop-dotfiles-test .

help:
	@echo "Desktop targets: install update upgrade packages stow unstow test test-bootstrap pomo clean"
