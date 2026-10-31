// Colores del wallpaper para Quickshell. matugen los escribe en ~/.cache/matugen/quickshell.json
// (plantilla: ~/.config/matugen/templates/quickshell.json) y aquí se leen en vivo.
// Van fuera de ~/.config/quickshell a propósito: cualquier cambio en esa carpeta recarga
// Quickshell entero, y eso cortaría el fundido de WallpaperFade.qml al cambiar de fondo.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    readonly property color accent:              colors.accent
    readonly property color accentText:          colors.accentText
    readonly property color accentContainer:     colors.accentContainer
    readonly property color accentContainerText: colors.accentContainerText

    FileView {
        path: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/matugen/quickshell.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: colors
            // Valores por defecto hasta que matugen genere el fichero
            property string accent:              "#8caaee"
            property string accentText:          "#002f65"
            property string accentContainer:     "#1d4583"
            property string accentContainerText: "#d8e2ff"
        }
    }
}
