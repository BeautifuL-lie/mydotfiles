#!/usr/bin/env bash

current_mode="$(cat ~/.mode 2>/dev/null || echo "light")"

if [ "$current_mode" = "dark" ]; then
    change-mode light
    swaync-client -rs
else
    change-mode dark
    swaync-client -rs
fi
