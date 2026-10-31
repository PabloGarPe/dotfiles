#!/usr/bin/env bash
#
# Genera los colores del sistema a partir del wallpaper (lo llama waypaper como post_command).
# Si es un vídeo, saca un fotograma con ffmpeg y usa ese.
#
#   from-wallpaper.sh <imagen|vídeo>

src=$1
[[ -f $src ]] || { echo "Uso: $0 <imagen|vídeo>" >&2; exit 1; }

case ${src,,} in
    *.mp4|*.mkv|*.webm|*.mov|*.avi|*.m4v|*.wmv|*.flv|*.ogv)
        frame="${XDG_RUNTIME_DIR:-/tmp}/matugen-frame.png"
        # Un fotograma a 1 s (los primeros suelen ser negros); si el vídeo es más corto, el primero
        ffmpeg -loglevel error -y -ss 1 -i "$src" -frames:v 1 "$frame" ||
            ffmpeg -loglevel error -y -i "$src" -frames:v 1 "$frame" || exit 1
        src=$frame
        ;;
esac

matugen image "$src" -m dark --prefer saturation

# Iconos: Papirus-Dark con carpetas del color del wallpaper
~/.config/matugen/papirus-matugen.py

# Cabecera del tema de rofi (themes/aurora.rasi): franja central del fondo
mkdir -p ~/.cache/rofi
ffmpeg -loglevel error -y -i "$src" -frames:v 1 \
    -vf "scale=1240:-2,crop=1240:400" ~/.cache/rofi/banner.png
