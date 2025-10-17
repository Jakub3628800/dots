#!/bin/zsh

export PATH="$PATH:/opt/nvim-linux64/bin"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export NVM_DIR="$HOME/.nvm"

. $HOME/.profile
. $HOME/.bash_aliases
if [ -f "$HOME/.bash_aliases_local" ]; then
    . $HOME/.bash_aliases_local
fi

setopt PROMPT_SUBST
setopt HIST_FIND_NO_DUPS
setopt share_history

export HISTFILESIZE=1000000000
export HISTSIZE=1000000000
export HISTFILE=~/.cache/.zsh_history

zstyle ':omz:plugins:ssh-agent' lazy yes
export SSH_ASKPASS_REQUIRE=force_cli

if [ -z "${DISABLE_SSH_AGENT_PLUGIN:-}" ]; then
  . $HOME/.zshlib/plugins/ssh-agent.plugin.zsh
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

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

[ -s "/home/jk/.bun/_bun" ] && source "/home/jk/.bun/_bun"

if [ ! -f /usr/local/bin/starship ]; then
    eval "$(starship init zsh)"
fi

eval "$(direnv hook zsh)"
eval "$(zoxide init zsh)"

alias zf='cd "$(zoxide query -l | fzf)"'
