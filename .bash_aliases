#!/bin/bash
# custom scripts for various things
#alias monitor="~/.monitor.sh"
#alias sound="~/.sound.sh"
#alias soundmute="~/.sound.sh -100"

alias lock="i3lock"

# Typos
alias grpe='grep'
alias cd..="cd .."

# clipboard with xclip
alias xclipb='xclip -selection clipboard'

# Adding extra arguments
alias ls="ls -G -CF"
alias la="ls -a"
alias ll="ls -lG -la"
alias grep='grep --color=auto --line-buffered'

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

# pre-commit
alias prec='pre-commit run --all-files'

# pycharm
alias charm='pycharm.sh'
alias pycharm='pycharm.sh'
