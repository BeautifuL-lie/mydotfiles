#!/usr/bin/env bash

swaync-client -cp 2>/dev/null
wall_dir="$HOME/Pictures/Wallpapers"
cacheDir="$HOME/.cache/wallcache"
[ -d "$cacheDir" ] || mkdir -p "$cacheDir"

monitors=$(swww query | grep "Output" | awk '{print $2}')
icon_size=220
rofi_override="element-icon{size:${icon_size}px;}"
rofi_command="rofi -i -show -dmenu -theme $HOME/.config/rofi/applets/wallSelect.rasi -theme-str $rofi_override"

get_optimal_jobs() {
    local cores=$(nproc)
    (( cores <= 2 )) && echo 2 || echo $(( (cores > 4) ? 4 : cores-1 ))
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
            echo "$current_md5" > "$md5_file"
        fi
        rm -f "$lock_file"
    ) 200>"$lock_file"
}

export -f process_image
export wall_dir cacheDir

rm -f "${cacheDir}"/.lock_* 2>/dev/null || true

# File untuk tracking proses
CACHE_RUNNING="/tmp/wallpaper_cache_running_$"

# Tampilkan loading popup jika proses lebih dari 2 detik
(
    sleep 1
    if [ -f "$CACHE_RUNNING" ]; then
        rofi -e "Caching Wallpaper..." -theme "$HOME/.config/rofi/applets/loading.rasi" &
        echo $! > "/tmp/wallpaper_loading_rofi_$"
    fi
) &
LOADING_PID=$!

# Mulai proses caching
touch "$CACHE_RUNNING"

find "$wall_dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \) -print0 | \
xargs -0 -P "$PARALLEL_JOBS" -I {} bash -c 'process_image "{}"'

# Selesai - tutup loading
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

if pidof rofi > /dev/null; then
    pkill rofi
fi

wall_selection=$(find "${wall_dir}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) -print0 |
    xargs -0 basename -a |
    LC_ALL=C sort -V |
    while IFS= read -r A; do
        if [[ "$A" =~ \.gif$ ]]; then
            printf "%s\n" "$A"
        else
            printf '%s\x00icon\x1f%s/%s\n' "$A" "${cacheDir}" "$A"
        fi
    done | $rofi_command)

SCHEMEFILE="$HOME/.cache/scheme"
[[ ! -f "$SCHEMEFILE" ]] && echo "dark" > "$SCHEMEFILE"
read -r scheme < "$SCHEMEFILE"

# Apply wallpaper with swww
matugen image "${wall_dir}/${wall_selection}" -m "$scheme"