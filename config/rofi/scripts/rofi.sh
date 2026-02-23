#!/usr/bin/env bash

STATE_FILE="/tmp/rofi_state"

rm -rf /tmp/clipboard 2>/dev/null

# Check if rofi running
if pgrep -x "rofi" >/dev/null; then
  CURRENT=$(cat "$STATE_FILE" 2>/dev/null)
  if [ "$CURRENT" == "$1" ]; then
    # If same binds, close rofi
    pkill -x rofi
    rm -f "$STATE_FILE"
    exit 0
  else
    # if different → kill rofi then open it
    pkill -x rofi
    sleep 0.1
  fi
fi

case "$1" in
app | wallpaper | powermenu | clipboard) ;;
*)
  exit 1
  ;;
esac

swaync-client -cp 2>/dev/null

if [ "$1" == "app" ]; then
  echo "app" >"$STATE_FILE"
  rofi -show drun -theme ~/.config/rofi/applets/app.rasi &
elif [ "$1" == "wallpaper" ]; then
  echo "wallpaper" >"$STATE_FILE"
  ~/.config/rofi/scripts/wallpaper-select.sh &
elif [ "$1" == "powermenu" ]; then
  echo "powermenu" >"$STATE_FILE"
  ~/.config/rofi/scripts/powermenu.sh &
elif [ "$1" == "clipboard" ]; then
  echo "clipboard" >"$STATE_FILE"
  touch /tmp/clipboard
  ~/.config/rofi/scripts/clipboard.sh &
fi
