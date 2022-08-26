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

alias aptup='sudo apt update && sudo apt upgrade'

# clipboard with xclip
alias xcc='xclip -selection clipboard'

# Locking screen
alias lock="i3lock --color 000000"

# git shortcuts
alias g='git'
alias gs='git status'
alias gc='git checkout'
alias gl='git log'
alias gb='git branch'
alias gtrash='git reset HEAD && git checkout -- .'
alias gpushup='git branch --show-current | xargs git push --set-upstream origin'

# docker shortcuts
alias d='docker'
alias dc='docker-compose'
alias dk='docker ps -q | xargs docker kill'

# pre-commit
alias preca='pre-commit run --all-files'
alias precs='git status --short | sed "s/M//g" | xargs pre-commit run --files'
alias prec1='pre-commit run --from-ref HEAD~1 --to-ref=HEAD'
alias prec2='pre-commit run --from-ref HEAD~2 --to-ref=HEAD'
alias prec3='pre-commit run --from-ref HEAD~3 --to-ref=HEAD'
