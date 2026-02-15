#!/usr/bin/env bash

wall_dir="$HOME/Pictures/Wallpapers"
cacheDir="$HOME/.cache/wallcache"
[ -d "$cacheDir" ] || mkdir -p "$cacheDir"

monitor_width=$(niri msg focused-output | awk 'NR==2 {print $3}' | cut -d 'x' -f1)

scale_factor=$(niri msg focused-output | awk 'NR==7 {print $2}')

icon_size=$(echo "scale=2; ($monitor_width * 14) / ($scale_factor * 96)" | bc)

# Rofi Override
rofi_override="element-icon{size:${icon_size}px;}"
rofi_command="rofi -i -show -dmenu -theme $HOME/.config/rofi/applets/wallpaper-select.rasi -theme-str $rofi_override"

get_optimal_jobs() {
  local cores=$(nproc)
  ((cores <= 2)) && echo 2 || echo $(((cores > 4) ? 4 : cores - 1))
}

PARALLEL_JOBS=$(get_optimal_jobs)

process_image() {
  local imagen="$1"
  local nombre_archivo=$(basename "$imagen")
  local cache_file="${cacheDir}/${nombre_archivo}"
  local md5_file="${cacheDir}/.${nombre_archivo}.md5"
  local lock_file="${cacheDir}/.lock_${nombre_archivo}"
  local current_md5=$(xxh64sum "$imagen" | cut -d' ' -f1)

  (
    flock -x 200
    if [ ! -f "$cache_file" ] || [ ! -f "$md5_file" ] || [ "$current_md5" != "$(cat "$md5_file" 2>/dev/null)" ]; then
      magick "$imagen" -resize 500x500^ -gravity center -extent 500x500 "$cache_file"
      echo "$current_md5" >"$md5_file"
    fi
    rm -f "$lock_file"
  ) 200>"$lock_file"
}

export -f process_image
export wall_dir cacheDir

rm -f "${cacheDir}"/.lock_* 2>/dev/null || true

# Tracking Process file
CACHE_RUNNING="/tmp/wallpaper_cache_running_$"

# Show Loading if past 1 sec
(
  sleep 1
  if [ -f "$CACHE_RUNNING" ]; then
    rofi -e "Caching Wallpaper..." -theme "$HOME/.config/rofi/applets/loading.rasi" &
    echo $! >"/tmp/wallpaper_loading_rofi_$"
  fi
) &
LOADING_PID=$!

# Start Caching
touch "$CACHE_RUNNING"

find "$wall_dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \) -print0 |
  xargs -0 -P "$PARALLEL_JOBS" -I {} bash -c 'process_image "{}"'

# Finish / Close Loading
rm -f "$CACHE_RUNNING"
kill "$LOADING_PID" 2>/dev/null
kill $(cat "/tmp/wallpaper_loading_rofi_$" 2>/dev/null) 2>/dev/null
rm -f "/tmp/wallpaper_loading_rofi_$"

# Cleanup orphan cache
for cached in "$cacheDir"/*; do
  [ -f "$cached" ] || continue
  original="${wall_dir}/$(basename "$cached")"
  if [ ! -f "$original" ]; then
    nombre_archivo=$(basename "$cached")
    rm -f "$cached" \
      "${cacheDir}/.${nombre_archivo}.md5" \
      "${cacheDir}/.lock_${nombre_archivo}"
  fi
done

rm -f "${cacheDir}"/.lock_* 2>/dev/null || true

wall_selection=$(find "${wall_dir}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) -print0 |
  xargs -0 basename -a |
  LC_ALL=C sort -V |
  while IFS= read -r A; do
    if [[ "$A" =~ \.gif$ ]]; then
      printf "%s\n" "$A"
    else
      printf '%s\x00icon\x1f%s/%s\n' "$A" "${cacheDir}" "$A"
    fi
  done | sort | $rofi_command)

if [ -z "$wall_selection" ]; then exit 0; fi

MODE_FILE="$HOME/.mode"
[[ ! -f "$MODE_FILE" ]] && echo "dark" >"$MODE_FILE"
read -r mode <"$MODE_FILE"

rm -f ~/.custom-color 2>/dev/null
matugen image "${wall_dir}/${wall_selection}" -m "$mode" --source-color-index 0
ln -sf "${wall_dir}/${wall_selection}" ~/.wallpaper
