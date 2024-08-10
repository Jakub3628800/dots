#!/bin/bash
sudo apt-get install -y \
    zsh \
    eza \
	batcat \
    stow \
    neofetch \
    direnv \
	neovim \
    vim \
    flameshot \
    slack \
    pavucontrol-qt \
    xclip \
    python3-virtualenv \
    vlc \
	xcompmgr \
	nitrogen \
    curl \
    nitrogen \
    postgresql-client-common \
    redshift \
    golang-go \
    zsh \
    direnv \
    openvpn \
    tree \
    jq \
    gammastep \
    gh \
    htop \
    pass \
    expect \
    xdotool \
    tig \
    wdisplays \
    swaylock \
    py3status \
    sqlite3 \
    i3 \
    sway \
    i3lock \
    pass \
    pass-extension-otp

# Docker
sudo apt-get install -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Installing pip packages..."
SYSTEM_VIRTUALENV=$HOME/.local/bin/system_environment
virtualenv $SYSTEM_VIRTUALENV
$SYSTEM_VIRTUALENV/bin/pip install autorandr==1.14.post1 \
                        pre-commit==3.6.0 \
                        ruff==0.4.1 \
                        virtualenvwrapper==6.1.0
