#!/bin/bash

# basics
alias ls="ls -a --color=auto"
alias ll="ls -lah --color=auto"
alias la="ls"

alias cd..="cd .."
alias cd.="cd .."
alias ..='cd ..'
alias ...='cd ../..'

alias grep='grep --color=auto --line-buffered'
alias grpe='grep'

# clipboard with xclip
alias xcc='xclip -selection clipboard'

# locking screen
lock() {
	if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
		swaylock --color 000000
	elif [ "$XDG_SESSION_TYPE" = "x11" ]; then
		i3lock --color 000000
	else
		echo "XDG_SESSION_TYPE not set"
	fi
}

# git
alias g='git'
alias gs='git status'
alias gc='git checkout'
alias gl='git log'
alias gb='git branch'
alias gtrash='git reset HEAD && git checkout -- .'
alias gpushup='git branch --show-current | xargs git push --set-upstream origin'

alias ghmerge='gh pr merge -m -d'

ghpr() {
	gh pr create
	exit_code=$?

	if [ $exit_code -eq 0 ]; then
    	echo "Firing up the PR checker in the background..."
    	~/.local/bin/prchecker.py &
	else
    	echo "Not running prchecker, pr create failed with exit code $exit_code"
	fi
}

# docker
alias d='docker'
alias dc='docker compose'
alias dkill='docker ps -q | xargs docker kill'

# python
alias prec='pre-commit run'
alias rr='ruff format'

# keyboard
alias k='keyboard'
