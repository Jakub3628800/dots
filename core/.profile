# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi


# vim as default editor
export VISUAL=vim
export EDITOR="$VISUAL"


# virtualenvwrapper
# https://bitbucket.org/virtualenvwrapper/virtualenvwrapper/src/master/docs/source/install.rst?mode=view
export WORKON_HOME="~/repos/.virtualenvs"
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
source /home/jk/.local/bin/system_environment/bin/virtualenvwrapper.sh
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/home/jk/go/bin

# History files
export HISTFILE=$HOME/.cache/.bash_history
export ZSH_COMPDUMP=$HOME/.cache/.zcompdump-$HOST
export LESSHISTFILE=$HOME/.cache/.lesshst
