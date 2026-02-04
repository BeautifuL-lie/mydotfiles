#!/bin/bash

# Simpan file status
STATE_FILE="/tmp/rofi_state"

if pgrep -x "wlogout" >/dev/null; then
  exit 0
fi

# Cek apakah ada rofi jalan
if pgrep -x "rofi" >/dev/null; then
  CURRENT=$(cat "$STATE_FILE" 2>/dev/null)
  if [ "$CURRENT" == "$1" ]; then
    # Kalau tombol sama ditekan lagi → tutup saja
    pkill -x rofi
    rm -f "$STATE_FILE"
    exit 0
  else
    # Kalau beda → kill dulu, nanti lanjut buka yang baru
    pkill -x rofi
    sleep 0.1
  fi
fi

case "$1" in
  app|wallpaper|clipboard)
    ;;
  *)
    exit 1
    ;;
esac

swaync-client -cp 2>/dev/null

# Jalankan sesuai argumen
if [ "$1" == "app" ]; then
  echo "app" >"$STATE_FILE"
  rofi -show drun -theme ~/.config/rofi/applets/app.rasi &
elif [ "$1" == "wallpaper" ]; then
  echo "wallpaper" >"$STATE_FILE"
  ~/.config/rofi/scripts/wallpaper-select.sh &
elif [ "$1" == "clipboard" ]; then
  echo "clipboard" >"$STATE_FILE"
  ~/.config/rofi/scripts/clipboard.sh &
fi
