#!/bin/zsh

typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/go/bin"
  /usr/local/go/bin
  /opt/nvim-linux64/bin
  $path
)

export NVM_DIR="$HOME/.nvm"
export VISUAL=nvim
export EDITOR="$VISUAL"
export LESSHISTFILE="$HOME/.cache/.lesshst"
export RUFF_CACHE_DIR="$HOME/.cache/ruff"
export ZSH_COMPDUMP="$HOME/.cache/.zcompdump-$HOST"

_source_if_safe() {
  local file="$1"
  local resolved
  if [ ! -e "$file" ]; then
    return 0
  fi
  resolved="$(realpath "$file" 2>/dev/null)" || return 0
  if [ -n "$(find "$resolved" -maxdepth 0 -type f -user "$(id -un)" ! -perm /022 2>/dev/null)" ]; then
    . "$file"
  else
    echo "Skipping unsafe source file: $file" >&2
  fi
}

_source_if_safe "$HOME/.profile"
_source_if_safe "$HOME/.bash_aliases"
_source_if_safe "$HOME/.bash_aliases_local"
_source_if_safe "$HOME/.zshrc_local"

setopt PROMPT_SUBST
setopt HIST_FIND_NO_DUPS
setopt share_history

HISTSIZE=100000
SAVEHIST=100000
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d "${HISTFILE:h}" ]] || mkdir -p -- "${HISTFILE:h}"

# Start one agent for the whole user session, but let ssh(1) add keys on first use.
# Preserve a valid forwarded agent; otherwise use the systemd user service.
if [[ -z "${SSH_AUTH_SOCK:-}" || ! -S "$SSH_AUTH_SOCK" ]]; then
  unset SSH_AUTH_SOCK SSH_AGENT_PID
  _ssh_agent_socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/dots-ssh-agent.socket"
  if [[ ! -S "$_ssh_agent_socket" ]] && (( $+commands[systemctl] )); then
    systemctl --user start dots-ssh-agent.service >/dev/null 2>&1
  fi
  if [[ -S "$_ssh_agent_socket" ]]; then
    export SSH_AUTH_SOCK="$_ssh_agent_socket"
  fi
  unset _ssh_agent_socket
fi
export SSH_ASKPASS_REQUIRE=never

fzf-history-widget() {
  local selected num
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
  selected=( $(fc -rl 1 | fzf --tiebreak=index --query="${LBUFFER}" +m) )
  if [ -n "$selected" ]; then
    num=$selected[1]
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
    fi
  fi
  zle reset-prompt
}

zle     -N   fzf-history-widget
bindkey '^R' fzf-history-widget

# Word jumping with Ctrl+Left/Right arrows
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

_source_if_safe "$NVM_DIR/nvm.sh"
_source_if_safe "$NVM_DIR/bash_completion"

if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi

if (( ! $+functions[compdef] )); then
  autoload -Uz compinit
  compinit -d "$ZSH_COMPDUMP"
fi

_rr() {
  if (( CURRENT == 2 )); then
    _command_names
  fi
}
compdef _rr rr

_source_if_safe "$HOME/.gvm/scripts/gvm"

unfunction _source_if_safe
