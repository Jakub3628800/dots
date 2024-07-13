#!/bin/bash
sudo apt-get install -y \
    zsh \
    stow \
    direnv \
    vim \
    flameshot \
    slack \
    pavucontrol-qt \
    xclip \
    python3-virtualenv \
    python3.10-venv \
    vlc \
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
if [ -n "$VIRTUAL_ENV" ]; then
    echo "Script is supposed to install dependencies in the system, not in a virtual environment. Skipping."
else

    PIP_REQUIRE_VIRTUALENV=false pip install --user \
        autorandr==1.14.post1 \
        tldr==3.2.0 \
        pre-commit==3.6.0 \
        ruff==0.4.1
fi
