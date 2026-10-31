#!/usr/bin/env bash
# Instalador de los dotfiles (Arch / CachyOS).
#
#   curl -fsSL https://raw.githubusercontent.com/PabloGarPe/dotfiles/main/.github/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --sddm six-eyes --nvim
#
# Opciones:
#   --no-deps        no instala paquetes con pacman/paru
#   --sddm [TEMA]    instala los temas de SDDM y activa TEMA (crimson-moon por defecto)
#   --nvim           descarga los plugins de Neovim y sus LSPs (Go, C/C++, Rust)
#   -h, --help       muestra esta ayuda
#
# Si ~/.dotfiles ya existe, solo actualiza (pull). Los ficheros que choquen con los del
# repo se mueven a ~/.dotfiles-backup/<fecha>/ antes de hacer checkout.
set -euo pipefail

REPO_HTTPS=https://github.com/PabloGarPe/dotfiles.git
REPO_SSH=git@github.com:PabloGarPe/dotfiles.git
GIT_DIR=$HOME/.dotfiles
BACKUP=$HOME/.dotfiles-backup/$(date +%F_%H%M%S)

PACKAGES=(
    git zsh fzf
    hyprland xdg-desktop-portal-hyprland hyprsunset waybar quickshell rofi kitty dolphin dunst
    waypaper mpvpaper matugen socat jq ffmpeg imagemagick python-pillow python-numpy
    grim slurp wl-clipboard
    inter-font ttf-jetbrains-mono-nerd papirus-icon-theme
    neovim go gcc clang rust
)
OPTIONAL=(cachyos-zsh-config brave-bin librewolf sbctl)   # se instalan si existen en tus repos

main() {
# Con "curl | bash" la entrada estándar es el propio script: pacman, sudo y chsh leen del terminal
if [[ ! -t 0 ]] && (: </dev/tty) 2>/dev/null; then exec </dev/tty; fi

deps=1 sddm_theme="" nvim=0
while (($#)); do
    case $1 in
        --no-deps) deps=0 ;;
        --sddm) sddm_theme=crimson-moon
                if [[ ${2:-} && $2 != -* ]]; then sddm_theme=$2; shift; fi ;;
        --nvim) nvim=1 ;;
        -h|--help) sed -n '2,15p' "$0" 2>/dev/null || echo "Ver cabecera en $REPO_HTTPS"; exit 0 ;;
        *) echo "Opción desconocida: $1" >&2; exit 1 ;;
    esac
    shift
done

say()  { printf '\e[1;35m==>\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m!!\e[0m %s\n' "$*" >&2; }
dots() { git --git-dir="$GIT_DIR" --work-tree="$HOME" "$@"; }

[[ $EUID -ne 0 ]] || { echo "Ejecútalo como tu usuario, no como root." >&2; exit 1; }
command -v pacman >/dev/null || { echo "Este instalador es para Arch/CachyOS (pacman)." >&2; exit 1; }

# 1. Paquetes ------------------------------------------------------------------
if ((deps)); then
    say "Instalando paquetes"
    extra=()
    for p in "${OPTIONAL[@]}"; do
        pacman -Si "$p" &>/dev/null && extra+=("$p") || warn "$p no está en tus repos, lo salto"
    done
    sudo pacman -S --needed "${PACKAGES[@]}" "${extra[@]}"
fi
command -v git >/dev/null || { echo "Falta git (quita --no-deps o instálalo)." >&2; exit 1; }

# 2. Repo bare -----------------------------------------------------------------
if [[ -d $GIT_DIR ]]; then
    say "~/.dotfiles ya existe: actualizando"
    dots pull --ff-only
else
    say "Clonando $REPO_HTTPS en ~/.dotfiles"
    git clone --bare "$REPO_HTTPS" "$GIT_DIR"
    dots remote set-url --push origin "$REPO_SSH"   # pull por HTTPS, push por SSH
    dots config status.showUntrackedFiles no

    # Mueve a la copia de seguridad los ficheros que ya existen y chocarían
    conflicts=$(dots ls-tree -r --name-only HEAD | while IFS= read -r f; do
        if [[ -e $HOME/$f || -L $HOME/$f ]]; then printf '%s\n' "$f"; fi; done)
    if [[ -n $conflicts ]]; then
        say "Moviendo ficheros existentes a $BACKUP"
        while IFS= read -r f; do
            mkdir -p "$BACKUP/$(dirname "$f")"
            mv "$HOME/$f" "$BACKUP/$f"
        done <<<"$conflicts"
    fi
    dots checkout
    # Un clon bare no trae refs remotas: las configura para que 'dots pull' funcione
    dots config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
    dots fetch -q origin
    dots branch -q --set-upstream-to=origin/main main
fi

# 3. Shell ---------------------------------------------------------------------
if [[ $(getent passwd "$USER" | cut -d: -f7) != */zsh ]]; then
    say "Cambiando la shell por defecto a zsh"
    chsh -s "$(command -v zsh)" || warn "No se pudo cambiar la shell (hazlo con: chsh -s /bin/zsh)"
fi
[[ -f /usr/share/cachyos-zsh-config/cachyos-config.zsh ]] \
    || warn ".zshrc usa cachyos-zsh-config (oh-my-zsh + p10k); fuera de CachyOS tendrás que adaptarlo"

# 4. Iconos: Papirus-Dark con carpetas del color del wallpaper (se regenera con waypaper)
if [[ -d /usr/share/icons/Papirus ]]; then
    say "Generando el tema de iconos Papirus-Matugen"
    "$HOME/.config/matugen/papirus-matugen.py" || warn "No se pudo generar Papirus-Matugen"
    gsettings set org.gnome.desktop.interface icon-theme Papirus-Matugen 2>/dev/null || true
fi

# 5. LibreWolf: copia el tema al perfil real si no se llama igual que el del repo
lw=$HOME/.config/librewolf/librewolf
src=$(compgen -G "$lw/*.default-release/chrome" | head -1 || true)
if [[ -n $src && -f $lw/profiles.ini ]]; then
    for prof in "$lw"/*.default-release; do
        [[ $prof/chrome == "$src" ]] && continue
        say "Copiando el tema de LibreWolf a $(basename "$prof")"
        cp -r "$src" "$prof/"
        cp "$(dirname "$src")/user.js" "$prof/"
    done
fi

# 6. Opcionales ----------------------------------------------------------------
if [[ -n $sddm_theme ]]; then
    say "Instalando tema SDDM: $sddm_theme"
    sudo pacman -S --needed sddm qt6-multimedia
    "$HOME/.local/share/sddm-themes/install.sh" "$sddm_theme"
fi

if ((nvim)); then
    say "Instalando plugins de Neovim y LSPs"
    nvim --headless "+Lazy! restore" +qa
    nvim --headless -c 'Lazy! load mason.nvim' \
        -c 'MasonInstall gopls clangd rust-analyzer codelldb delve goimports gofumpt golangci-lint' +qa
fi

say "Hecho."
cat <<EOF

  - Usa 'dots status', 'dots add', 'dots commit', 'dots push' (alias en .zshrc).
  - Tema de Brave: brave://extensions -> modo desarrollador -> Cargar descomprimida
    -> ~/.local/share/brave-themes/nocturne
  - Secure Boot (opcional): ~/secureboot.sh
EOF
[[ -d $BACKUP ]] && echo "  - Tus ficheros anteriores están en $BACKUP"
echo "  - Cierra sesión y entra en Hyprland."
}

main "$@"; exit
