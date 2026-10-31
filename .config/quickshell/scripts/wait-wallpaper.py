#!/usr/bin/env python3
"""Espera a que mpvpaper esté mostrando un fondo concreto (lo usa WallpaperFade.qml).

  wait-wallpaper.py <ruta>

Se conecta al socket IPC de mpv que abre waypaper (/tmp/mpv-socket-*), observa la
propiedad "path" y sale en cuanto mpv ha cargado esa ruta y ha pintado el primer
fotograma (evento playback-restart). Sale igualmente a los 8 s si no ocurre.
"""
import glob, json, os, select, socket, sys, time

target = os.path.realpath(os.path.expanduser(sys.argv[1]))
deadline = time.monotonic() + 8

def connect():
    while time.monotonic() < deadline:
        for p in glob.glob("/tmp/mpv-socket-*"):
            try:
                s = socket.socket(socket.AF_UNIX)
                s.connect(p)
                return s
            except OSError:
                pass
        time.sleep(0.05)   # waypaper puede estar reiniciando mpvpaper
    sys.exit(0)

def same(p):
    return p and os.path.realpath(os.path.expanduser(p)) == target

while time.monotonic() < deadline:
    s = connect()
    s.sendall(b'{"command": ["observe_property", 1, "path"]}\n')
    loaded, buf = False, b""
    try:
        while time.monotonic() < deadline:
            r, _, _ = select.select([s], [], [], 0.2)
            if not r:
                continue
            chunk = s.recv(65536)
            if not chunk:
                break   # mpvpaper se ha cerrado: reconecta al nuevo
            buf += chunk
            *lines, buf = buf.split(b"\n")
            for line in lines:
                try:
                    ev = json.loads(line)
                except ValueError:
                    continue
                if ev.get("event") == "property-change" and ev.get("name") == "path":
                    loaded = same(ev.get("data"))
                elif loaded and ev.get("event") == "playback-restart":
                    sys.exit(0)
    except OSError:
        pass
    finally:
        s.close()
