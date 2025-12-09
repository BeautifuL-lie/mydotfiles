#!/usr/bin/env bash

rofi_state=$(cat /tmp/rofi_state)

if pgrep -x rofi >/dev/null && [[ "$rofi_state" == "wallpaper" ]]; then
    pkill -x rofi 2>/dev/null
fi

swaync-client -t -sw