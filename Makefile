.PHONY: install update link upgrade system-upgrade test clean help
.PHONY: install-core install-desktop install-nvim
.PHONY: link-core link-desktop link-nvim
.PHONY: update-core update-desktop update-nvim
.PHONY: upgrade-core upgrade-desktop upgrade-nvim
.PHONY: test-core test-desktop test-nvim

install: install-core install-desktop install-nvim

# Backward-compatible, cheap configuration refresh.
update: link

link: link-core link-desktop link-nvim

upgrade: upgrade-core upgrade-desktop upgrade-nvim

system-upgrade:
	@sudo apt-get update
	@sudo apt-get upgrade -y

test: test-core test-desktop test-nvim

install-core:
	@$(MAKE) -C core install

install-desktop:
	@$(MAKE) -C desktop install

install-nvim:
	@$(MAKE) -C nvim install

link-core:
	@$(MAKE) -C core stow

link-desktop:
	@$(MAKE) -C desktop stow

link-nvim:
	@$(MAKE) -C nvim stow

update-core: link-core

update-desktop: link-desktop

update-nvim: link-nvim

upgrade-core:
	@$(MAKE) -C core upgrade

upgrade-desktop:
	@$(MAKE) -C desktop upgrade

upgrade-nvim:
	@$(MAKE) -C nvim upgrade

test-core:
	@$(MAKE) -C core test

test-desktop:
	@$(MAKE) -C desktop test

test-nvim:
	@$(MAKE) -C nvim test

clean:
	@$(MAKE) -C core unstow
	@$(MAKE) -C desktop unstow
	@$(MAKE) -C nvim unstow

help:
	@echo "Dotfiles targets:"
	@echo "  install         Install packages, Neovim, and dotfiles"
	@echo "  link / update   Refresh dotfile links only"
	@echo "  upgrade         Reconcile managed packages and dotfile links"
	@echo "  system-upgrade  Upgrade all APT packages on the host"
	@echo "  test             Run package tests"
	@echo "  clean            Remove managed dotfile links"
