// Fundido al cambiar de fondo. mpvpaper cambia de golpe, así que se tapa el fondo
// actual con una imagen fija suya, se cambia por debajo y, cuando mpv confirma que ya
// pinta el fondo nuevo (scripts/wait-wallpaper.py, por su socket IPC), la imagen se desvanece.
//   qs ipc call wallfade change <ruta>     (el selector de fondos lo llama directamente)
// La imagen fija del fondo actual la guarda ~/.config/matugen/from-wallpaper.sh en
// ~/.cache/wallpaper/current.jpg. Si no existe, se cambia sin fundido.
// Va en la capa Bottom: encima de mpvpaper (Background) y debajo de las ventanas.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    readonly property string still: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache")
                                    + "/wallpaper/current.jpg"
    property bool mapped: false
    property bool covered: false     // la imagen fija tapa (o está tapando) el fondo
    property real coverOpacity: 0    // opacidad de la imagen fija, compartida por todos los monitores
    property bool waiting: false     // esperando a que mpvpaper cargue el fondo nuevo
    property string pending: ""

    function change(path) {
        if (mapped) return
        pending = path
        mapped = true
        covered = true
        fadeOut.stop()
        fadeIn.restart()
    }

    function setWallpaper() {
        applier.command = ["waypaper", "--wallpaper", pending]
        applier.startDetached()
    }

    function reveal() {
        waiting = false
        covered = false
        fadeIn.stop()
        fadeOut.restart()
    }

    IpcHandler {
        target: "wallfade"
        function change(path: string): void { root.change(path) }
    }

    Process { id: applier }

    // Cuando la imagen ya tapa el fondo, se cambia por debajo
    Timer {
        id: coverTimer
        interval: 60
        onTriggered: {
            root.waiting = true
            waiter.command = [Quickshell.shellDir + "/scripts/wait-wallpaper.py", root.pending]
            waiter.running = true      // empieza a escuchar antes de que waypaper lo cambie
            root.setWallpaper()
        }
    }
    // mpv ya pinta el fondo nuevo: un instante más para que el primer fotograma llegue a pantalla
    Process { id: waiter; onExited: revealTimer.restart() }
    Timer { id: revealTimer; interval: 120; onTriggered: root.reveal() }

    // Entrada rápida (tapa el fondo actual) y salida lenta (descubre el nuevo)
    NumberAnimation {
        id: fadeIn
        target: root; property: "coverOpacity"
        to: 1; duration: 200; easing.type: Easing.OutCubic
        onFinished: coverTimer.start()
    }
    NumberAnimation {
        id: fadeOut
        target: root; property: "coverOpacity"
        to: 0; duration: 1200; easing.type: Easing.InOutSine
        onFinished: root.mapped = false
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.mapped
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}

            WlrLayershell.namespace: "wallpaper-fade"   // sin animación: hypr/conf/rules.lua
            WlrLayershell.layer: WlrLayer.Bottom

            Image {
                id: img
                anchors.fill: parent
                // Vuelve a "" al terminar cada fundido, así que siempre se relee la imagen actual
                source: root.mapped ? "file://" + root.still : ""
                cache: false
                asynchronous: false
                fillMode: Image.PreserveAspectCrop
                opacity: root.coverOpacity
                // Sin imagen fija (primer arranque): cambio directo, sin fundido
                onStatusChanged: if (status === Image.Error && root.covered && !root.waiting) {
                    fadeIn.stop()
                    root.covered = false
                    root.coverOpacity = 0
                    root.mapped = false
                    root.setWallpaper()
                }
            }
        }
    }
}
