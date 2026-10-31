#!/usr/bin/env bash
# Secure Boot con sbctl + GRUB (CachyOS, dual boot con Windows)
#
#   ./secureboot.sh prepare   -> instala sbctl y reinstala GRUB apto para Secure Boot
#   (BIOS: borrar claves de Secure Boot -> Setup Mode)
#   ./secureboot.sh enroll    -> crea claves, las registra (+ Microsoft) y firma todo
#   (BIOS: activar Secure Boot)
#   ./secureboot.sh check     -> comprueba el estado
set -euo pipefail

ESP=/boot/efi

# Con Secure Boot, GRUB no puede cargar módulos desde disco: van todos dentro del binario.
WANTED_MODULES="all_video bli boot btrfs cat chain configfile echo efifwsetup efi_gop efinet
ext2 fat font gettext gfxmenu gfxterm gfxterm_background gzio halt help iso9660 jpeg
keystatus loadenv loopback linux ls lsefi lsefimmap lsefisystab memdisk minicmd normal
ntfs part_gpt part_msdos password_pbkdf2 png probe reboot regexp search search_fs_uuid
search_fs_file search_label serial sleep smbios squash4 test tpm true video xfs zstd"

need_root() { [[ $EUID -eq 0 ]] || exec sudo "$0" "$@"; }

modules() {
    local m out=()
    for m in $WANTED_MODULES; do
        [[ -f /usr/lib/grub/x86_64-efi/$m.mod ]] && out+=("$m")
    done
    echo "${out[*]}"
}

setup_mode() { sbctl status 2>/dev/null | grep -qiE 'Setup Mode:.*Enabled'; }

prepare() {
    pacman -S --needed --noconfirm sbctl
    echo ">> Copia de seguridad del ESP en /root/esp-backup-$(date +%F)"
    cp -a "$ESP" "/root/esp-backup-$(date +%F)"

    echo ">> Reinstalando GRUB (removable, sin shim, módulos integrados)"
    grub-install --target=x86_64-efi --efi-directory="$ESP" --removable \
        --disable-shim-lock --modules="$(modules)"
    grub-mkconfig -o /boot/grub/grub.cfg
    echo
    sbctl status
    cat <<'EOF'

Hecho. Siguiente paso:
  1. Reinicia y comprueba que GRUB, Linux y Windows siguen arrancando (Secure Boot aún apagado).
  2. Entra en la BIOS (Supr) -> Advanced Mode (F7) -> Boot -> Secure Boot ->
     Key Management -> "Clear Secure Boot Keys" (o "Delete all Secure Boot variables").
     NO actives Secure Boot todavía. Guarda (F10) y arranca Linux.
  3. Ejecuta:  ./secureboot.sh enroll
EOF
}

enroll() {
    command -v sbctl >/dev/null || { echo "Ejecuta primero: $0 prepare" >&2; exit 1; }
    if ! setup_mode; then
        echo "El firmware NO está en Setup Mode. Borra las claves de Secure Boot en la BIOS primero." >&2
        sbctl status; exit 1
    fi
    [[ -d /var/lib/sbctl/keys || -d /usr/share/secureboot/keys ]] || sbctl create-keys

    # -m: incluye las claves de Microsoft (Windows, firmware de la GPU y otros Option ROMs)
    sbctl enroll-keys --microsoft

    echo ">> Firmando GRUB y kernels (se guardan en la BD de sbctl: el hook de pacman los re-firma al actualizar)"
    local f
    for f in "$ESP/EFI/BOOT/BOOTX64.EFI" "$ESP"/EFI/*/grubx64.efi /boot/vmlinuz-*; do
        [[ -f $f ]] && sbctl sign -s "$f"
    done
    echo
    sbctl verify || true
    cat <<'EOF'

Último paso: BIOS -> Boot -> Secure Boot -> OS Type: "Windows UEFI mode"
(Secure Boot Mode: Custom/Standard da igual, las claves ya son las tuyas). Guarda (F10).
Después, en Linux:  ./secureboot.sh check
EOF
}

check() {
    sbctl status
    echo
    sbctl verify
}

case "${1:-}" in
    prepare) need_root "$@"; prepare ;;
    enroll)  need_root "$@"; enroll ;;
    check)   need_root "$@"; check ;;
    *) sed -n '2,10p' "$0"; exit 1 ;;
esac
