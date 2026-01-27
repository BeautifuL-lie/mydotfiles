#!/usr/bin/env bash

mode=$(cat ~/.mode)

if [ $mode == "dark" ]; then
  target="light"
else
  target="dark"
fi

rm -f ~/.config/wlogout/icons/*.png
cp ~/.config/wlogout/icons/"$target"/*.png ~/.config/wlogout/icons/
