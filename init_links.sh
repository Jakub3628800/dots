#!/bin/bash
# Initiate links between files.

for element in .bash_aliases .local/bin/monitor.sh .local/bin/sound.sh .vimrc .xinitrc .Xmodmap .config/i3/config .local/bin/restore_workspaces
do
  if ! [ -f ~/$element ]; then
    echo "$element  does not exists, creating now."
    cp "$PWD/home/$element" ~/$element
  fi
  ln -f ~/$element "$PWD/home/$element"
done
