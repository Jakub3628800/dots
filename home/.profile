# ~/.profile: executed by Bourne-compatible login shells.

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

export VISUAL=vim
export EDITOR="$VISUAL"

mesg n 2> /dev/null || true
