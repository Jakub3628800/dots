# Bare make only shows the verbs. Each verb names one operation.
.DEFAULT_GOAL := help
# Package managers and Stow must run sequentially, even with make -j.
.NOTPARALLEL:
# Select fewer components for a machine without a desktop:
# make install COMPONENTS="core nvim"
COMPONENTS ?= core desktop nvim
BOOTSTRAP_COMPONENTS := $(filter core desktop,$(COMPONENTS))
# The recipes use + because make -n cannot see $(MAKE) inside this macro.
each = @set -eu; for component in $(1); do $(MAKE) -C "$$component" $(2); done

.PHONY: install packages link clean system-upgrade test test-scripts test-bootstrap help

install packages link clean test:
	+$(call each,$(COMPONENTS),$@)

test: test-scripts
test-scripts:
	@python3 -m unittest discover -s tests

system-upgrade:
	+@$(MAKE) -C core system-upgrade

test-bootstrap:
	+$(call each,$(BOOTSTRAP_COMPONENTS),test-bootstrap)

help:
	@echo 'make install         install packages, Neovim, and links'
	@echo 'make packages        install the managed packages and Neovim'
	@echo 'make link            refresh links only'
	@echo 'make clean           remove links'
	@echo 'make system-upgrade  upgrade all APT packages on the host'
	@echo 'make test            run fast configuration tests'
	@echo 'make test-bootstrap  test a clean Ubuntu package bootstrap in Docker'
	@echo 'Set COMPONENTS to select components, for example COMPONENTS="core nvim".'
