#!/usr/bin/env bash
#
# Cambia el volumen con wpctl y lo muestra en una notificación de dunst con barra.
# Todas comparten la misma stack tag, así que se reemplazan en vez de amontonarse.
#
#   volume.sh up | down | mute | mic

sink=@DEFAULT_AUDIO_SINK@
source=@DEFAULT_AUDIO_SOURCE@

case $1 in
    up)   wpctl set-mute "$sink" 0; wpctl set-volume -l 1 "$sink" 5%+ ;;
    down) wpctl set-volume "$sink" 5%- ;;
    mute) wpctl set-mute "$sink" toggle ;;
    mic)  wpctl set-mute "$source" toggle ;;
    *)    echo "Uso: $0 up|down|mute|mic" >&2; exit 1 ;;
esac

notify() { # notify <icono> <título> <porcentaje>
    notify-send -a Volumen -u low -t 1500 -i "$1" \
        -h string:x-dunst-stack-tag:volume -h int:value:"$3" "$2"
}

if [[ $1 == mic ]]; then
    read -r _ vol muted < <(wpctl get-volume "$source")
    pct=$(awk -v v="$vol" 'BEGIN { printf "%d", v * 100 + 0.5 }')
    if [[ $muted ]]; then
        notify microphone-sensitivity-muted "Micrófono silenciado" 0
    else
        notify microphone-sensitivity-high "Micrófono activado" "$pct"
    fi
    exit
fi

read -r _ vol muted < <(wpctl get-volume "$sink")
pct=$(awk -v v="$vol" 'BEGIN { printf "%d", v * 100 + 0.5 }')

if [[ $muted || $pct -eq 0 ]]; then
    notify audio-volume-muted "Silenciado" 0
else
    if   (( pct < 34 )); then icon=audio-volume-low
    elif (( pct < 67 )); then icon=audio-volume-medium
    else                      icon=audio-volume-high
    fi
    notify "$icon" "Volumen  ${pct} %" "$pct"
fi
