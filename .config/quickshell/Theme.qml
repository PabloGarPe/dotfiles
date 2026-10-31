// Paleta del tema macOS de waybar (~/.config/waybar/style.css), para que el
// panel parezca parte de la barra. El acento sale de Matugen.qml.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color panel:     Qt.rgba(28 / 255, 28 / 255, 30 / 255, 0.62) // @bar, algo más opaco
    readonly property color tile:      Qt.rgba(1, 1, 1, 0.07)
    readonly property color tileHover: Qt.rgba(1, 1, 1, 0.11)
    readonly property color control:   Qt.rgba(1, 1, 1, 0.14)                     // @hover
    readonly property color border:    Qt.rgba(1, 1, 1, 0.12)                     // @border
    readonly property color text:      "#ffffff"
    readonly property color text2:     "#86868b"                                  // @text-2

    readonly property string font:     "Inter"
    readonly property string iconFont: "JetBrainsMono Nerd Font"

    readonly property int radius:     18
    readonly property int tileRadius: 14
    readonly property int gap:        10
}
