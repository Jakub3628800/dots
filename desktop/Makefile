APT_PACKAGES := bemenu xclip xdotool pass pass-extension-otp sway kanshi wtype mako-notifier gammastep swaylock

.PHONY: all install update upgrade packages stow unstow clean system-upgrade test help

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
	@docker build -t desktop-dotfiles-test .

help:
	@echo "Desktop targets: install update upgrade packages stow unstow test clean"
