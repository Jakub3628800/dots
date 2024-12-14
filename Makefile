# Default target
.PHONY: all
all: python_packages apt stow

UV_EXISTS := $(shell command -v uv 2> /dev/null)
HOME_DIR := $(shell echo $$HOME)
VENV_PATH := $(HOME_DIR)/.local/bin/system_environment
APT_PACKAGES := \
	zsh \
    	eza \
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
    	i3lock \
    	redshift \
    	swaylock \
    	stow \
	tmux \
    	ripgrep

.PHONY: install-uv
install-uv:
ifndef UV_EXISTS
	@curl -LsSf https://astral.sh/uv/install.sh | sh
else
	@echo "uv is already installed"
endif

.PHONY: python_packages
python_packages: install-uv
	uv lock
	ln -sf $(CURDIR)/.venv $(VENV_PATH)
	uv sync

.PHONY: apt
apt:
	@sudo apt-get install -y $(APT_PACKAGES)

.PHONY: stow
stow: apt
	@stow --target=$(HOME_DIR) core
	@stow --target=$(HOME_DIR) i3
