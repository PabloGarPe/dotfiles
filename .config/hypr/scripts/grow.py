#!/usr/bin/env python3
"""Redimensiona la ventana activa con las flechas (Super+Ctrl+flechas).

    grow.py <left|right|up|down> [pasos_px]

La flecha mueve un borde hacia ese lado: si la ventana tiene sitio hacia
allí, crece; si ese lado ya da al límite de la pantalla, empuja el borde
opuesto y la ventana encoge.

En mosaico (dwindle) es lo que hace un resize relativo de forma nativa: mueve
el borde compartido en el sentido del desplazamiento. Las ventanas flotantes
se simulan con resize + move.
"""

import json
import subprocess
import sys

STEP = 40
# Distancia máxima (px) al límite útil del monitor para considerar que un
# borde "toca" la pantalla: cubre gaps_out + borde de la ventana.
EDGE_TOLERANCE = 50

# dirección -> (dx, dy) del borde que se mueve
DIRECTIONS = {
    "left":  (-1, 0),
    "right": (1, 0),
    "up":    (0, -1),
    "down":  (0, 1),
}


def hyprctl_json(*args):
    return json.loads(subprocess.check_output(["hyprctl", *args, "-j"]))


def dispatch(lua):
    subprocess.run(["hyprctl", "dispatch", lua], stdout=subprocess.DEVNULL)


def touches_screen(win, mon, direction):
    """True si el borde de la ventana en esa dirección da al límite del monitor."""
    (x, y), (w, h) = win["at"], win["size"]
    res_left, res_top, res_right, res_bottom = mon["reserved"]
    left = mon["x"] + res_left
    top = mon["y"] + res_top
    right = mon["x"] + mon["width"] - res_right
    bottom = mon["y"] + mon["height"] - res_bottom
    gap = {
        "left":  x - left,
        "right": right - (x + w),
        "up":    y - top,
        "down":  bottom - (y + h),
    }[direction]
    return gap <= EDGE_TOLERANCE


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in DIRECTIONS:
        sys.exit(f"Uso: {sys.argv[0]} <left|right|up|down> [px]")
    direction = sys.argv[1]
    step = int(sys.argv[2]) if len(sys.argv) > 2 else STEP
    dx, dy = DIRECTIONS[direction]

    win = hyprctl_json("activewindow")
    if not win:
        return

    if not win["floating"]:
        dispatch(f"hl.dsp.window.resize({{ x = {dx * step}, y = {dy * step}, relative = true }})")
        return

    mon = next(m for m in hyprctl_json("monitors") if m["id"] == win["monitor"])
    sx, sy = abs(dx) * step, abs(dy) * step
    if touches_screen(win, mon, direction):
        # Encoge: reduce el tamaño y, hacia derecha/abajo, desplaza la ventana
        dispatch(f"hl.dsp.window.resize({{ x = {-sx}, y = {-sy}, relative = true }})")
        if dx > 0 or dy > 0:
            dispatch(f"hl.dsp.window.move({{ x = {sx}, y = {sy}, relative = true }})")
    else:
        # Crece: aumenta el tamaño y, hacia izquierda/arriba, desplaza la ventana
        dispatch(f"hl.dsp.window.resize({{ x = {sx}, y = {sy}, relative = true }})")
        if dx < 0 or dy < 0:
            dispatch(f"hl.dsp.window.move({{ x = {-sx}, y = {-sy}, relative = true }})")

if __name__ == "__main__":
    main()
