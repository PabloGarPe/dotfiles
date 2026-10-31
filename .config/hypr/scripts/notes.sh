#!/usr/bin/env bash
# Notas rápidas con rofi.
#   notes.sh add   → pide una nota y la guarda (SUPER+SPACE)
#   notes.sh view  → lista las notas, la más reciente arriba (SUPER+SHIFT+SPACE)
#       Enter  copia la nota al portapapeles
#       Alt+d  borra la nota seleccionada
#       Alt+e  abre el archivo en nvim
#
# Archivo: ~/Notes/quick.md, una nota por línea: "- [YYYY-MM-DD HH:MM] texto"

NOTES="${QUICK_NOTES_FILE:-$HOME/Notes/quick.md}"
mkdir -p "$(dirname "$NOTES")"
touch "$NOTES"

add() {
	local note
	note=$(rofi -dmenu -p "Nota" -l 0 -mesg "Enter para guardar · Esc para cancelar" </dev/null) || exit 0
	note="${note#"${note%%[![:space:]]*}"}" # trim inicial
	[ -z "$note" ] && exit 0
	printf -- '- [%s] %s\n' "$(date '+%Y-%m-%d %H:%M')" "$note" >>"$NOTES"
	notify-send -a "Notas" -t 2000 "Nota guardada" "$note"
}

# Color de acento (tags) desde la paleta de matugen, con valor por defecto
ACCENT=$(grep -oP 'm-tertiary:\s*\K#[0-9a-fA-F]{6}' "$HOME/.config/rofi/colors/matugen.rasi" 2>/dev/null)
ACCENT="${ACCENT:-#e0c38c}"

# Markdown en línea → markup Pango para rofi (-markup-rows)
render() {
	ACCENT="$ACCENT" perl -CSD -Mutf8 -pe '
		s/&/&amp;/g; s/</&lt;/g; s/>/&gt;/g;
		s/^- //;
		s{^\[([^\]]*)\]\s*}{<span alpha="55%" size="small">$1</span>  };
		s{`([^`]+)`}{<tt><span background="#ffffff1a">$1</span></tt>}g;
		s{\*\*(.+?)\*\*|__(.+?)__}{"<b>".($1//$2)."</b>"}ge;
		s{(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?!\w)|(?<!\w)_(?!\s)(.+?)(?<!\s)_(?!\w)}{"<i>".($1//$2)."</i>"}ge;
		s{~~(.+?)~~}{<s>$1</s>}g;
		s{\[([^\]]+)\]\(([^)]+)\)}{<u>$1</u>}g;
		s{\[ \]}{☐}g; s{\[[xX]\]}{☑}g;
		s{(</span>  )(#{1,6}) (.*)$}{$1 . "<b><span size=\"large\">$3</span></b>"}e;
		s{(^|\s)(#[\w\-]+)}{$1<span foreground="$ENV{ACCENT}" weight="bold">$2</span>}g;
	'
}

view() {
	while :; do
		local total sel code
		total=$(wc -l <"$NOTES")
		if [ "$total" -eq 0 ]; then
			notify-send -a "Notas" -t 2000 "Notas" "No hay notas todavía (SUPER+SPACE para crear una)"
			exit 0
		fi

		sel=$(tac "$NOTES" | render | rofi -dmenu -i -markup-rows -p "Notas ($total)" -format i \
			-kb-custom-1 "Alt+d" -kb-custom-2 "Alt+e" \
			-mesg "Enter: copiar · Alt+d: borrar · Alt+e: editar en nvim")
		code=$?
		[ -z "$sel" ] && [ "$code" -ne 11 ] && exit 0

		local line=$((total - sel)) # índice invertido → número de línea en el archivo
		case $code in
		0) # copiar el texto (sin la fecha)
			sed -n "${line}p" "$NOTES" | sed -E 's/^- \[[^]]*\] //' | tr -d '\n' | wl-copy
			notify-send -a "Notas" -t 1500 "Copiada al portapapeles"
			exit 0
			;;
		10) # borrar y volver a mostrar la lista
			sed -i "${line}d" "$NOTES"
			;;
		11)
			exec kitty --class quick-notes -e nvim + "$NOTES"
			;;
		*) exit 0 ;;
		esac
	done
}

case "$1" in
add) add ;;
view) view ;;
*) echo "uso: $0 add|view" >&2; exit 1 ;;
esac
