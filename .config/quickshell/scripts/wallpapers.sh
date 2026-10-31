#!/usr/bin/env bash
#
# Lista los fondos de waypaper para el selector de Quickshell (WallpaperPicker.qml)
# y genera las miniaturas que falten en ~/.cache/wallpaper-thumbs.
#
# Salida, una línea por fondo:  ruta<TAB>miniatura<TAB>image|video
# Primera línea:                current<TAB>ruta del fondo actual

shopt -s nullglob nocaseglob

conf="$HOME/.config/waypaper/config.ini"
folder=$(sed -n 's/^folder *= *//p' "$conf"); folder=${folder/#\~/$HOME}
current=$(sed -n 's/^wallpaper *= *//p' "$conf"); current=${current/#\~/$HOME}
cache="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-thumbs"
mkdir -p "$cache"

printf 'current\t%s\n' "$current"

thumb() {   # <fichero> <miniatura>
    local seek=()
    case ${1,,} in *.mp4|*.mkv|*.webm|*.mov|*.avi|*.m4v|*.gif) seek=(-ss 1) ;; esac
    ffmpeg -loglevel error -y "${seek[@]}" -i "$1" -frames:v 1 \
        -vf "scale=640:360:force_original_aspect_ratio=increase,crop=640:360" -q:v 3 "$2" 2>/dev/null ||
    ffmpeg -loglevel error -y -i "$1" -frames:v 1 \
        -vf "scale=640:360:force_original_aspect_ratio=increase,crop=640:360" -q:v 3 "$2"
}
export -f thumb

pending=()
for f in "$folder"/*.{jpg,jpeg,png,webp,bmp,gif,mp4,mkv,webm,mov,avi,m4v}; do
    # El nombre de la miniatura cambia si el fichero cambia (ruta + fecha de modificación)
    t="$cache/$(printf '%s%s' "$f" "$(stat -c %Y "$f")" | sha1sum | cut -c1-16).jpg"
    [[ -s $t ]] || pending+=("$f" "$t")
    case ${f,,} in *.mp4|*.mkv|*.webm|*.mov|*.avi|*.m4v) type=video ;; *) type=image ;; esac
    lines+=("$f"$'\t'"$t"$'\t'"$type")
done

# Genera las que falten en paralelo
((${#pending[@]})) && printf '%s\0' "${pending[@]}" | xargs -0 -n2 -P"$(nproc)" bash -c 'thumb "$0" "$1"'

printf '%s\n' "${lines[@]}" | sort -f
