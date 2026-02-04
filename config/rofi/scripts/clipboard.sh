#!/usr/bin/env bash
trap "exit" SIGTERM SIGINT

while true; do
  result=$(
    rofi -i -dmenu \
      -kb-custom-1 "Control-Delete" \
      -kb-custom-2 "ALT-Delete" \
      -config ~/.config/rofi/applets/cliphist.rasi < <(cliphist list)
  )

  case "$?" in
  1)
    exit
    ;;
  0)
    case "$result" in
    "")
      continue
      ;;
    *)
      cliphist decode <<<"$result" | wl-copy
      exit
      ;;
    esac
    ;;
  10)
    cliphist delete <<<"$result"
    ;;
  11)
    cliphist wipe
    ;;
  esac
done
