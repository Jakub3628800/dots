# Default target
.PHONY: all
all: install-uv apt stow

UV_EXISTS := $(shell command -v uv 2> /dev/null)
HOME_DIR := $(shell echo $$HOME)
APT_PACKAGES := \
	zsh \
    	bat \
    	vim \
    	xclip \
    	python3-virtualenv \
    	tig \
    	gh \
    	xcompmgr \
    	nitrogen \
    	zsh \
    	xdotool \
    	pass \
    	pass-extension-otp \
    	i3 \
    	sway \
	wtype \
	mako-notifier \
	gammastep \
    	i3lock \
    	redshift \
    	swaylock \
    	stow \
	tmux \
    	ripgrep \
	picom

OPTIONAL_PACKAGES := \
	bemenu

.PHONY: install-uv
install-uv:
ifndef UV_EXISTS
	@curl -LsSf https://astral.sh/uv/install.sh | sh
else
	@echo "uv is already installed"
	@echo "Checking for uv update"
	uv self update
endif


.PHONY: apt
apt:
	@sudo apt-get install -y $(APT_PACKAGES)
	@for pkg in $(OPTIONAL_PACKAGES); do \
		echo "Installing optional package $$pkg..."; \
		sudo apt-get install -y $$pkg || echo "Warning: Could not install optional package $$pkg - continuing anyway"; \
	done

.PHONY: stow
stow: apt
	@stow --target=$(HOME_DIR) core
	@stow --target=$(HOME_DIR) i3
