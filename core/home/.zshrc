#!/bin/zsh

export PATH="$PATH:/opt/nvim-linux64/bin"
export NVM_DIR="$HOME/.nvm"


export CARGO_BIN="$HOME/.cargo/bin"
export PATH="$CARGO_BIN:$PATH"

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

export HISTFILESIZE=1000000000
export HISTSIZE=1000000000
export HISTFILE=~/.cache/.zsh_history

zstyle ':omz:plugins:ssh-agent' lazy no
zstyle ':omz:plugins:ssh-agent' lifetime 8h
export SSH_ASKPASS_REQUIRE=force_cli

if [ -z "${DISABLE_SSH_AGENT_PLUGIN:-}" ]; then
  _source_if_safe "$HOME/.zshlib/plugins/ssh-agent.plugin.zsh"
fi

show_virtual_env() {
  if [[ -n "$VIRTUAL_ENV" && -n "$DIRENV_DIR" ]]; then
    echo "($(basename $VIRTUAL_ENV))"
  fi
}

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

if [ ! -f /usr/local/bin/starship ]; then
    eval "$(starship init zsh)"
fi

eval "$(direnv hook zsh)"
eval "$(zoxide init zsh)"

alias zf='cd "$(zoxide query -l | fzf)"'

if (( ! $+functions[compdef] )); then
  autoload -Uz compinit
  compinit
fi

_rr() {
  if (( CURRENT == 2 )); then
    _command_names
  fi
}
compdef _rr rr

_source_if_safe "$HOME/.gvm/scripts/gvm"

typeset -U path PATH
unfunction _source_if_safe
