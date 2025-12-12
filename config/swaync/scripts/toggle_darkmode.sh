#!/usr/bin/env bash

current_scheme="$(cat ~/.mode 2>/dev/null || echo "light")"

if [ "$current_scheme" = "dark" ]; then
    chsch light
    swaync-client -rs
else
    chsch dark
    swaync-client -rs
fi
