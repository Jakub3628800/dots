#!/bin/bash

# Better ls, if exa is installed
command -v eza &> /dev/null && alias ls="eza  -a --icons"
alias ll="ls -lh"
alias lwc="ls -la | wc -l"

alias cd..="cd .."
alias cd.="cd .."
alias ..='cd ..'
alias ...='cd ../..'

alias cdg='cd "$(git rev-parse --show-toplevel)"'


# clipboard with xclip
alias xcc='wl-copy'

# retry alias for rr !!
function rr() {
    until eval "$1"; do
        sleep 2
    done
}


# locking screen
lock() {
	if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
		swaylock --color 000000
	else
                slock
	fi
}

# git
alias g='git'
alias gs='git status'
alias gc='git checkout'
alias gl='git log'
alias gtrash='git reset HEAD && git checkout -- .'
alias gpushup='git branch --show-current | xargs git push --set-upstream origin'

alias ghmerge='gh pr merge --rebase --delete-branch'

git-branch-switch() {
  local branches branch
  branches=$(git --no-pager branch -vv --sort=-committerdate) &&
  branch=$(echo "$branches" | fzf +m) &&
  git checkout "$(echo "$branch" | awk '{print $1}' | sed "s/.* //")"
}

alias gb='git branch'
alias gbb='git-branch-switch'

alias tg='tig'

ghpr() {
	gh pr create
	exit_code=$?

	if [ $exit_code -eq 0 ]; then
    	echo "Firing up the PR checker in the background..."
        {uvx --from git+https://github.com/Jakub3628800/gists action-checker} &
	#	gh pr view --web
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
alias prec='uvx pre-commit run'
alias preca='uvx pre-commit run --all-files'

# keyboard
alias k='keyboard'

alias wget='wget --no-hsts'

# vim
#
alias vim='nvim'
alias llm='nvim -c "GpChatNew"'
alias nv='nvim .'
alias nv.='nvim .'
alias nano='nvim'
