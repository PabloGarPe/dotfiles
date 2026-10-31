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
| Activar Secure Boot con claves propias (sbctl + GRUB) | `secureboot.sh` |

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

## Secure Boot

`secureboot.sh` activa Secure Boot en CachyOS con GRUB y dual boot con Windows, usando claves propias firmadas con `sbctl` (sin shim). Incluye las claves de Microsoft, así que Windows y los Option ROMs de la GPU siguen arrancando. Se hace en tres pasos, con visitas a la BIOS entre medias:

```sh
./secureboot.sh prepare   # instala sbctl, copia el ESP a /root y reinstala GRUB con los módulos integrados
# BIOS: borrar las claves de Secure Boot (Setup Mode), sin activarlo todavía
./secureboot.sh enroll    # crea y registra las claves (+ Microsoft) y firma GRUB y los kernels
# BIOS: activar Secure Boot (OS Type: "Windows UEFI mode")
./secureboot.sh check     # comprueba el estado y que todo está firmado
```

Los ficheros firmados quedan en la base de datos de `sbctl`, y su hook de pacman los vuelve a firmar en cada actualización del kernel o de GRUB.

## Uso

```sh
dots status
dots add .config/hypr/conf/keybinds.lua
dots commit -m "..."
dots push
```
