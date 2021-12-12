#!/bin/bash
# Initiate links between files.

for element in .bash_aliases .local/bin/monitor.sh .local/bin/sound.sh .vimrc .xinitrc .Xmodmap .config/i3/config
do
  if ! [ -f ~/$element ]; then
    echo "$element  does not exists, creating now."
    cp "$PWD/$element" ~/$element
  fi
  ln -f ~/$element "$PWD/$element"
done
