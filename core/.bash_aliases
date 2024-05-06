#!/bin/bash

# Basics - navigation
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

# Locking screen
lock() {
	if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
		swaylock --color 000000
	else
		i3lock --color 000000
	fi
}
#alias lock="i3lock --color 000000"

# git shortcuts
alias g='git'
alias gs='git status'
alias gc='git checkout'
alias gl='git log'
alias gb='git branch'
alias gtrash='git reset HEAD && git checkout -- .'
alias gpushup='git branch --show-current | xargs git push --set-upstream origin'

alias ghmerge='gh pr merge -m -d'

# docker shortcuts
alias d='docker'
alias dc='docker compose'
alias dkill='docker ps -q | xargs docker kill'

# python
alias python='python3'

# ruff
alias rr='ruff format'

# keyboard
alias k='keyboard'
