#!/usr/bin/env bash
# Instala los temas SDDM de esta carpeta y activa uno.
# Uso: ./install.sh [crimson-moon|six-eyes]   (por defecto: crimson-moon)
set -euo pipefail
dir="$(cd "$(dirname "$0")" && pwd)"
theme="${1:-crimson-moon}"
[[ -f "$dir/$theme/metadata.desktop" ]] || { echo "Tema desconocido: $theme" >&2; exit 1; }
for t in "$dir"/*/; do
    t="$(basename "$t")"
    sudo rm -rf "/usr/share/sddm/themes/$t"
    sudo cp -r "$dir/$t" /usr/share/sddm/themes/
done
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=%s\n' "$theme" | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
echo "Tema SDDM activo: $theme"
