#!/usr/bin/env bash
#
# Dock con auto-ocultado: un waybar por monitor, cada uno con su propia config generada.
#
#   dock.sh restart          (Re)arranca un dock oculto en cada monitor
#   dock.sh toggle <monitor> Muestra/oculta el dock de ese monitor (lo llama conf/dock.lua)

base="$HOME/.config/waybar/dock.jsonc"
style="$HOME/.config/waybar/style.css"
run="${XDG_RUNTIME_DIR:-/tmp}/waybar-dock"

case $1 in
    restart)
        # Dos reinicios a la vez (p. ej. recargas seguidas de Hyprland) duplicarían los docks
        exec 9>"${XDG_RUNTIME_DIR:-/tmp}/waybar-dock.lock"
        flock 9
        pkill -f "waybar -c $run/" ; sleep 0.2
        mkdir -p "$run"
        # Al iniciar sesión Hyprland puede no responder todavía
        for _ in {1..50}; do mons=$(hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null) && [[ -n $mons ]] && break; sleep 0.1; done
        for mon in $mons; do
            printf '{ "include": ["%s"], "output": "%s" }\n' "$base" "$mon" > "$run/$mon.jsonc"
            setsid -f waybar -c "$run/$mon.jsonc" -s "$style" >/dev/null 2>&1
        done
        ;;
    toggle)
        [[ -n $2 ]] || { echo "Uso: $0 toggle <monitor>" >&2; exit 1; }
        pkill -SIGUSR1 -f "waybar -c $run/$2.jsonc"
        ;;
    *)  echo "Uso: $0 {restart|toggle <monitor>}" >&2; exit 1 ;;
esac
