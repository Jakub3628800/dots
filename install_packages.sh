#!/bin/bash
sudo apt-get install -y \
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
    docker.io \
    docker-compose \
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
    tig \
    wdisplays \
    swaylock \
    py3status \
    sqlite3

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
