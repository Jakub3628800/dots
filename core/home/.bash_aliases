#!/bin/bash

# ls
command -v eza &> /dev/null && alias ls="eza  -a --icons"
alias ll="ls -lh"

# cd
alias cd..="cd .."
alias cd...="cd ../.."
alias cd....="cd ../../.."
alias cdg='cd "$(git rev-parse --show-toplevel)"'

# git
alias g='git'
alias gs='git status'
alias gl='git log'
alias gc='git checkout'
alias gpf='git push --force'
alias gds='git diff --staged'
gbb() {
  local branches branch
  branches=$(git --no-pager branch -vv --sort=-committerdate) &&
  branch=$(echo "$branches" | fzf +m) &&
  git checkout "$(echo "$branch" | awk '{print $1}' | sed "s/.* //")"
}

# tig
alias tg='tig'

# gh
alias ghmerge='gh pr merge --rebase --delete-branch'
ghpr() {
	gh pr create
	exit_code=$?

	if [ $exit_code -eq 0 ]; then
    	echo "Firing up the PR checker in the background..."
        action-checker
	#	gh pr view --web
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
alias preca='pre-commit run --all-files'

# vim
alias vim='nvim'
alias llm='nvim -c "GpChatNew"'
alias nv='nvim .'
alias nv.='nvim .'
alias nano='nvim'

# claude
alias cc='claude --dangerously-skip-permissions'
alias docker-compose='docker compose'

# other
function rr() {  # retry cmd
    until eval "$1"; do
        sleep 2
    done
}
copycat() { cat "$1" | wl-copy; }

alias wget='wget --no-hsts' # disable history file
alias tm='cmd-picker tmux'
alias xcc='wl-copy'
alias tt='make test'
