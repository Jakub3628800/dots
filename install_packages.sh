#!/bin/sh
sudo apt-get install -y \
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
    stow

SYSTEM_VIRTUALENV=$HOME/.local/bin/system_environment
echo "Installing pip packages in $SYSTEM_VIRTUALENV"
virtualenv $SYSTEM_VIRTUALENV
$SYSTEM_VIRTUALENV/bin/pip install --upgrade autorandr==1.14.post1 \
                        pre-commit==3.6.0 \
                        ruff==0.4.1 \
                        virtualenvwrapper==6.1.0 \
                        pip \
                        uv

# Also re-link files
stow --target=$HOME core
stow --target=$HOME i3
