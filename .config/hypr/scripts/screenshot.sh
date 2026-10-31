#!/usr/bin/env bash
#
# Captura de una zona (o ventana, haciendo clic sobre ella) con grim + slurp.
# Se guarda en ~/Pictures/Screenshots y se copia al portapapeles.
# Super+Shift+S / Impr Pant. ESC cancela.

dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Screenshots"
file="$dir/Captura_$(date +%Y-%m-%d_%H-%M-%S).png"
mkdir -p "$dir"

# Evita abrir dos selectores a la vez
pgrep -x slurp >/dev/null && exit 0

# Rectángulos de las ventanas visibles, para poder capturar una con un solo clic
windows=$(hyprctl clients -j | jq -r --argjson ws "$(hyprctl monitors -j | jq '[.[].activeWorkspace.id]')" \
    '.[] | select(.mapped and (.workspace.id as $w | $ws | index($w))) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')

geom=$(slurp -d -b '#00000066' -c '#0A84FFff' -s '#0A84FF22' -w 2 <<<"$windows") || exit 0

grim -g "$geom" "$file" || exit 1
wl-copy --type image/png < "$file"
notify-send -a "Captura" -i "$file" "Captura guardada" "Copiada al portapapeles\n${file/#$HOME/\~}"
