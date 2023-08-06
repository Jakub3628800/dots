#!/bin/bash
# Initiate links between files.

elements=$(find home -type f| xargs -n 1 | sed 's|home/||g' | xargs)
for element in $elements
do
  if ! [ -f ~/$element ]; then
    echo "$element  does not exists, creating now."
    cp "$PWD/home/$element" ~/$element
  fi
  ln -f ~/$element "$PWD/home/$element"
  echo "linked $element"
done
