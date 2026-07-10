APT_PACKAGES := \
	bemenu \
	gammastep \
	grim \
	i3status \
	kanshi \
	mako-notifier \
	pass \
	pass-extension-otp \
	pulseaudio-utils \
	slurp \
	sway \
	swaylock \
	wl-clipboard \
	wtype

.PHONY: all install update upgrade packages stow unstow clean system-upgrade test test-bootstrap help

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

system-upgrade:
	@sudo apt-get update
	@sudo apt-get upgrade -y

test:
	@set -e; tmp_home=$$(mktemp -d); \
		trap 'rm -rf "$$tmp_home"' 0 1 2 15; \
		stow -R -d . -t "$$tmp_home" --no-folding home; \
		HOME="$$tmp_home" sway --validate --config "$$tmp_home/.config/sway/config"; \
		status=0; timeout 1 i3status --config "$$tmp_home/.config/i3status/config" >/dev/null 2>&1 || status=$$?; \
		test "$$status" -eq 0 || test "$$status" -eq 124
	@if command -v luac >/dev/null 2>&1; then luac -p home/.wezterm.lua; \
	elif command -v wezterm >/dev/null 2>&1; then wezterm --config-file home/.wezterm.lua show-keys --lua >/dev/null; \
	else echo "Skipping WezTerm syntax check (luac/wezterm unavailable)"; fi
	@for script in home/.local/bin/*; do sh -n "$$script"; done

test-bootstrap:
	@docker build -t desktop-dotfiles-test .

help:
	@echo "Desktop targets: install update upgrade packages stow unstow test test-bootstrap clean"
