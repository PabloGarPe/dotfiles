#!/usr/bin/env python3
"""
Genera ~/.local/share/icons/Papirus-Matugen: Papirus-Dark con las carpetas del
color de Papirus más parecido al color principal del wallpaper (matugen).

No necesita root: en lugar de tocar /usr/share/icons como papirus-folders, crea
un tema de usuario que hereda de Papirus-Dark y solo redefine los iconos de
carpeta (enlaces simbólicos a la variante de color elegida).

Lo llama ~/.config/matugen/from-wallpaper.sh después de matugen.

  papirus-matugen.py            # color desde ~/.cache/matugen/primary
  papirus-matugen.py '#e4c36c'  # color concreto
  papirus-matugen.py teal       # variante de Papirus concreta
"""
import colorsys
import math
import os
import re
import shutil
import sys
from pathlib import Path

SRC = Path("/usr/share/icons")
BASES = ["Papirus", "Papirus-Dark"]  # Papirus-Dark gana si ambos definen el icono
BASE_COLOR = "blue"  # color por defecto de Papirus: los enlaces apuntan a *-blue*
DEST = Path.home() / ".local/share/icons/Papirus-Matugen"
PRIMARY_FILE = Path.home() / ".cache/matugen/primary"
# Variantes que son marcas/temas, no colores: no se eligen automáticamente
SKIP = {"adwaita", "breeze", "yaru", "nordic"}


def hex_to_rgb(h):
    h = h.lstrip("#")[:6]
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def papirus_colors():
    """{nombre: rgb} leyendo el color del cuerpo de cada folder-<color>.svg."""
    places = SRC / "Papirus/64x64/places"
    colors = {}
    for svg in places.glob("folder-*.svg"):
        name = svg.stem[len("folder-"):]
        if "-" in name or svg.is_symlink():
            continue
        m = re.search(r'fill:(#[0-9a-fA-F]{6})"\s+width="56"', svg.read_text())
        if m and (places / f"user-{name}-home.svg").exists():
            colors[name] = hex_to_rgb(m.group(1))
    return colors


def nearest(target, colors):
    """Color más cercano priorizando el tono (los de matugen son más pastel)."""
    th, tl, ts = colorsys.rgb_to_hls(*target)
    best, best_d = None, math.inf
    for name, rgb in colors.items():
        h, l, s = colorsys.rgb_to_hls(*rgb)
        if ts < 0.15:  # color casi gris: elegir entre grises por luminosidad
            d = abs(l - tl) + s
        else:
            if name in SKIP:
                continue
            dh = min(abs(h - th), 1 - abs(h - th))
            d = 4 * dh + abs(s - ts) * 0.5 + abs(l - tl) * 0.5
        if d < best_d:
            best, best_d = name, d
    return best


def build(color):
    tmp = DEST.with_name(DEST.name + ".tmp")
    shutil.rmtree(tmp, ignore_errors=True)
    links = {}  # "64x64/places" -> {nombre: destino absoluto}
    pat = re.compile(rf"^(folder|user)-{BASE_COLOR}([-.])")
    for base in BASES:
        for places in sorted((SRC / base).glob("*/places")):
            rel = f"{places.parent.name}/places"
            for f in places.iterdir():
                if not f.is_symlink():
                    continue
                target = os.readlink(f)
                if "/" in target or not pat.match(target):
                    continue
                new = places / pat.sub(rf"\1-{color}\2", target)
                if new.exists():
                    links.setdefault(rel, {})[f.name] = new.resolve()

    sections = []
    index = (SRC / "Papirus/index.theme").read_text()
    for rel in sorted(links):
        out = tmp / rel
        out.mkdir(parents=True)
        for name, dst in links[rel].items():
            (out / name).symlink_to(dst)
        m = re.search(rf"^\[{re.escape(rel)}\]\n(?:.+\n?)+", index, re.M)
        sections.append(m.group(0).strip() if m else
                        f"[{rel}]\nContext=Places\nSize={rel.split('x')[0]}\nType=Fixed")

    (tmp / "index.theme").write_text(
        "[Icon Theme]\n"
        "Name=Papirus-Matugen\n"
        f"Comment=Papirus-Dark con carpetas '{color}' (generado por papirus-matugen.py)\n"
        "Inherits=Papirus-Dark,breeze-dark,hicolor\n"
        f"Directories={','.join(sorted(links))}\n\n"
        + "\n\n".join(sections) + "\n")

    shutil.rmtree(DEST, ignore_errors=True)
    tmp.rename(DEST)
    return sum(len(v) for v in links.values())


def main():
    if not (SRC / "Papirus").is_dir():
        sys.exit("papirus-icon-theme no está instalado")
    colors = papirus_colors()
    if len(sys.argv) > 1:
        arg = sys.argv[1]
    elif PRIMARY_FILE.exists():
        arg = PRIMARY_FILE.read_text().strip()
    else:  # aún no se ha elegido wallpaper
        arg = BASE_COLOR
    color = arg if arg in colors else nearest(hex_to_rgb(arg), colors)
    n = build(color)
    print(f"Papirus-Matugen: carpetas '{color}' ({arg}), {n} iconos")


if __name__ == "__main__":
    main()
