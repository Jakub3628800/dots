#!/bin/bash

# Better ls, if exa is installed
command -v exa &> /dev/null && alias ls="exa  -a --icons"
alias ll="ls -lh"

# Better cat, if bat is installed
command -v batcat &> /dev/null && alias cat="batcat"

alias cd..="cd .."
alias cd.="cd .."
alias ..='cd ..'
alias ...='cd ../..'


# clipboard with xclip
alias xcc='xclip -selection clipboard'

# locking screen
lock() {
	if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
		swaylock --color 000000
	else
		i3lock --color 000000
	fi
}

# git
alias g='git'
alias gs='git status'
alias gc='git checkout'
alias gl='git log'
alias gb='git branch --sort=-committerdate'
alias gtrash='git reset HEAD && git checkout -- .'
alias gpushup='git branch --show-current | xargs git push --set-upstream origin'

alias ghmerge='gh pr merge --rebase --delete-branch'

ghpr() {
	gh pr create
	exit_code=$?

	if [ $exit_code -eq 0 ]; then
    	echo "Firing up the PR checker in the background..."
    	~/.local/bin/action_checker.py &
		gh pr view --web
	else
    	echo "Not running prchecker, pr create failed with exit code $exit_code"
	fi
}

alias prw='gh pr view --web'

# docker
alias d='docker'
alias dc='docker compose'
alias dkill='docker ps -q | xargs docker kill'

# python
alias prec='pre-commit run'
alias rr='ruff format'

# keyboard
alias k='keyboard'

alias wget='wget --no-hsts'
