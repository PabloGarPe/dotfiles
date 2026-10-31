#!/usr/bin/env bash
#
# Centro de control (rofi): multimedia y modo de energía.
# Se abre al pulsar el reloj de waybar.
#
# Funciona como modo script de rofi: rofi vuelve a llamar a este script en
# cada pulsación y la ventana se actualiza sin cerrarse.

theme="$HOME/.config/rofi/control-center/style.rasi"

# Sin ROFI_RETV no lo ha lanzado rofi: abre la ventana con este script como modo
if [[ -z $ROFI_RETV ]]; then
    exec rofi -show control -modi "control:$0" -eh 2 -selected-row 1 \
              -me-select-entry '' -me-accept-entry MousePrimary \
              -theme "$theme"
fi

# Escapa &, <, > y | (el separador de filas) para el markup de Pango
esc() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/|/\&#124;/g'; }

# Opciones de rofi y filas se separan con '|', porque cada fila ocupa dos líneas
opt()  { printf '\0%s\x1f%s|' "$1" "$2"; }
item() { printf '<span size="x-large">%s</span>\n<span size="small">%s</span>\0info\x1f%s|' "$2" "$3" "$1"; }

# Multimedia deja el menú abierto; el modo de energía lo cierra (sin filas, rofi sale).
if (( ROFI_RETV == 1 )); then
    case $ROFI_INFO in
        prev)  playerctl previous ;;
        play)  playerctl play-pause ;;
        next)  playerctl next ;;
        performance|balanced|power-saver)
            powerprofilesctl set "$ROFI_INFO"
            exit 0 ;;
    esac
    sleep 0.2
fi

# El separador se declara solo en la primera llamada; rofi lo recuerda
(( ROFI_RETV == 0 )) && printf '\0delim\x1f|\n'

status=$(playerctl status 2>/dev/null)
if [[ -n $status ]]; then
    title=$(playerctl metadata title 2>/dev/null | esc)
    artist=$(playerctl metadata artist 2>/dev/null | esc)
    player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null | esc)
    mesg="<b>${title:-Sin título}</b>"
    [[ -n $artist ]] && mesg+=$'\n'"${artist}"
    mesg+=$'\n'"<span size='small' alpha='60%'>${player} · ${status}</span>"
else
    mesg="<span alpha='60%'>󰝛  Nada sonando</span>"
fi
[[ $status == Playing ]] && play=("󰏤" "Pausar") || play=("󰐊" "Reproducir")

case $(powerprofilesctl get 2>/dev/null) in
    performance) opt active 3 ;;
    balanced)    opt active 4 ;;
    power-saver) opt active 5 ;;
esac

opt markup-rows true
opt no-custom true
opt keep-selection true
opt message "$mesg"

item prev        "󰒮" "Anterior"
item play        "${play[0]}" "${play[1]}"
item next        "󰒭" "Siguiente"
item performance "󰓅" "Rendimiento"
item balanced    "󰾅" "Equilibrado"
item power-saver "󰾆" "Ahorro"
