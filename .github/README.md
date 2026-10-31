# dotfiles

Hyprland (config en Lua) en CachyOS, con estética macOS Sequoia en oscuro.

| Qué | Dónde |
|---|---|
| Hyprland: atajos, reglas, autostart, dock, Alt+Tab | `.config/hypr/` |
| Barra de menú y dock auto-ocultable (waybar) | `.config/waybar/` |
| Fondos (waypaper + mpvpaper, imágenes y vídeo) | `.config/waypaper/` |
| Colores del sistema a partir del fondo (matugen) | `.config/matugen/` |
| Lanzador, menú de apagado, centro de control (rofi) | `.config/rofi/` |
| Neovim (LazyVim) | `.config/nvim/` |
| Tema "Nocturne" para Brave | `.local/share/brave-themes/nocturne/` |
| Tema "Nocturne" para LibreWolf | `.config/librewolf/librewolf/*/chrome/`, `user.js` |
| Shell (zsh + Powerlevel10k) | `.zshrc`, `.p10k.zsh` |

## Dependencias

```sh
sudo pacman -S hyprland waybar rofi kitty dolphin waypaper mpvpaper socat matugen \
  ffmpeg jq grim slurp wl-clipboard dunst hyprsunset xdg-desktop-portal-hyprland \
  inter-font ttf-jetbrains-mono-nerd imagemagick python-pillow python-numpy neovim
```

## Instalación (repo bare)

```sh
git clone --bare git@github.com:PabloGarPe/dotfiles.git ~/.dotfiles
alias dots='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
dots config status.showUntrackedFiles no
dots checkout   # si choca con ficheros existentes, muévelos antes
```

El tema de Brave se carga a mano: `brave://extensions` → modo desarrollador → *Cargar descomprimida* → `~/.local/share/brave-themes/nocturne`.

## Uso

```sh
dots status
dots add .config/hypr/conf/keybinds.lua
dots commit -m "..."
dots push
```
