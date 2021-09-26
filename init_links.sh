#!/bin/bash
# Initiate links between files.

for element in .bash_aliases .monitor.sh .sound.sh .vimrc .xinitrc .Xmodmap
do
  if ! [ -f ~/$element ]; then
    echo "$element  does not exists, creating now."
    cp /home/jakub/Dev/dots/$element ~/$element
  fi
  ln -f ~/$element /home/jakub/Dev/dots/$element
done
