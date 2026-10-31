// Selector de fondos: cinta horizontal en perspectiva sobre la pantalla desenfocada.
//   qs ipc call wallpapers toggle      (Super+Shift+W, botón "Fondo" del centro de control)
// ←/→ o rueda: moverse · Enter/clic: aplicar (waypaper → matugen) · Esc/clic fuera: cerrar
// La tarjeta central reproduce el vídeo si el fondo es animado.
import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

Scope {
    id: root

    property bool open: false
    property bool mapped: false
    property var targetScreen: null
    property string current: ""
    property var items: []
    property bool loading: false

    readonly property int cardW: 480
    readonly property int cardH: 270

    function show() {
        targetScreen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        unmapTimer.stop()
        mapped = true
        open = true
        loading = true
        loader.buffer = []
        loader.running = true
    }
    function hide() {
        if (!open) return
        open = false
        unmapTimer.restart()
    }
    function toggle() { open ? hide() : show() }

    function apply(path) {
        applier.command = ["waypaper", "--wallpaper", path]
        applier.startDetached()
        current = path
        hide()
    }

    function prettyName(path) {
        let n = path.split("/").pop().replace(/\.[^.]+$/, "")
        n = n.replace(/-(moewalls|wallsflow)-com$/, "")
             .replace(/(-hd)?-live(-wallpaper)?$/, "")
             .replace(/[-_]+/g, " ").trim()
        return n.charAt(0).toUpperCase() + n.slice(1)
    }

    IpcHandler {
        target: "wallpapers"
        function toggle(): void { root.toggle() }
        function open(): void { root.show() }
        function close(): void { root.hide() }
    }

    Timer { id: unmapTimer; interval: 260; onTriggered: root.mapped = false }
    Process { id: applier }

    // Lista de fondos + miniaturas (scripts/wallpapers.sh)
    Process {
        id: loader
        property var buffer: []
        command: [Quickshell.shellDir + "/scripts/wallpapers.sh"]
        stdout: SplitParser {
            onRead: line => {
                const f = line.split("\t")
                if (f[0] === "current") root.current = f[1]
                else if (f.length === 3) loader.buffer.push({ path: f[0], thumb: f[1], type: f[2] })
            }
        }
        onExited: {
            root.items = buffer
            root.loading = false
            // Empieza centrado en el fondo actual, sin animación
            const i = Math.max(0, root.items.findIndex(w => w.path === root.current))
            strip.highlightMoveDuration = 0
            strip.currentIndex = i
            strip.positionViewAtIndex(i, ListView.Center)
            Qt.callLater(() => strip.highlightMoveDuration = 380)
            strip.forceActiveFocus()
        }
    }

    PanelWindow {
        id: win
        visible: root.mapped
        screen: root.targetScreen

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore   // también tapa waybar
        color: "transparent"

        WlrLayershell.namespace: "quickshell-wallpapers"   // blur: hypr/conf/rules.lua
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // Fondo oscurecido (Hyprland lo desenfoca); clic fuera de la cinta = cerrar
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
            opacity: root.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent; onClicked: root.hide() }
        }

        Item {
            id: stage
            anchors.fill: parent
            opacity: root.open ? 1 : 0
            transform: Translate { y: root.open ? 0 : 40; Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Text {
                anchors.centerIn: parent
                visible: root.loading && root.items.length === 0
                text: "Cargando fondos…"
                font.family: Theme.font
                font.pixelSize: 15
                color: Theme.text2
            }

            ListView {
                id: strip
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -30
                height: root.cardH + 60

                model: root.items
                orientation: ListView.Horizontal
                spacing: -40   // las laterales se encogen; así quedan pegadas
                cacheBuffer: 4000
                focus: true
                keyNavigationWraps: false

                // La tarjeta actual siempre en el centro
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: width / 2 - root.cardW / 2
                preferredHighlightEnd: width / 2 + root.cardW / 2
                highlightMoveDuration: 380

                Keys.onEscapePressed: root.hide()
                Keys.onReturnPressed: if (currentIndex >= 0) root.apply(root.items[currentIndex].path)
                Keys.onEnterPressed: if (currentIndex >= 0) root.apply(root.items[currentIndex].path)

                // Rueda: una tarjeta por "clic" (acumula el delta de los touchpads)
                WheelHandler {
                    property real acc: 0
                    onWheel: e => {
                        acc += (e.angleDelta.y !== 0 ? e.angleDelta.y : -e.angleDelta.x)
                        while (acc >= 120) { strip.decrementCurrentIndex(); acc -= 120 }
                        while (acc <= -120) { strip.incrementCurrentIndex(); acc += 120 }
                    }
                }

                delegate: Item {
                    id: card
                    required property var modelData
                    required property int index

                    readonly property bool isCurrent: ListView.isCurrentItem
                    readonly property bool isApplied: modelData.path === root.current
                    // Distancia al centro, en tarjetas (negativo = a la izquierda)
                    readonly property real offset: (x + width / 2 - strip.contentX - strip.width / 2) / (root.cardW - 40)
                    readonly property real dist: Math.min(Math.abs(offset), 3)

                    width: root.cardW
                    height: strip.height
                    z: 100 - dist * 10
                    scale: 1 - Math.min(dist, 2) * 0.14
                    opacity: dist > 2.6 ? Math.max(0, 1 - (dist - 2.6) * 2.5) : 1

                    transform: Rotation {
                        origin.x: card.width / 2
                        origin.y: card.height / 2
                        axis { x: 0; y: 1; z: 0 }
                        angle: Math.max(-1, Math.min(1, card.offset)) * -32
                    }

                    // Sombra
                    Rectangle {
                        x: frame.x + 4; y: frame.y + 14
                        width: frame.width - 8; height: frame.height
                        radius: 20
                        color: Qt.rgba(0, 0, 0, card.isCurrent ? 0.45 : 0.25)
                    }

                    ClippingRectangle {
                        id: frame
                        width: root.cardW
                        height: root.cardH
                        anchors.centerIn: parent
                        radius: 18
                        color: "#1c1c1e"

                        Image {
                            anchors.fill: parent
                            source: "file://" + card.modelData.thumb
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize: Qt.size(640, 360)
                        }

                        // Vista previa en movimiento de la tarjeta central
                        Loader {
                            anchors.fill: parent
                            active: card.isCurrent && card.modelData.type === "video" && root.open && !strip.moving
                            sourceComponent: Video {
                                id: video
                                source: "file://" + card.modelData.path
                                muted: true
                                loops: MediaPlayer.Infinite
                                autoPlay: true
                                fillMode: VideoOutput.PreserveAspectCrop
                                opacity: playbackState === MediaPlayer.PlayingState ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                            }
                        }

                        // Oscurece las laterales
                        Rectangle {
                            anchors.fill: parent
                            color: "black"
                            opacity: Math.min(card.dist, 2) * 0.28
                        }

                        // Marca del fondo en uso
                        Rectangle {
                            visible: card.isApplied
                            anchors { left: parent.left; top: parent.top; margins: 12 }
                            implicitWidth: appliedRow.implicitWidth + 18
                            implicitHeight: 24
                            radius: 12
                            color: Qt.rgba(0, 0, 0, 0.55)
                            Row {
                                id: appliedRow
                                anchors.centerIn: parent
                                spacing: 5
                                Text { text: "󰄬"; font.family: Theme.iconFont; font.pixelSize: 12; color: Matugen.accent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "Actual"; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }

                        // Icono de fondo animado
                        Rectangle {
                            visible: card.modelData.type === "video"
                            anchors { right: parent.right; top: parent.top; margins: 12 }
                            implicitWidth: 28
                            implicitHeight: 24
                            radius: 12
                            color: Qt.rgba(0, 0, 0, 0.55)
                            Text { anchors.centerIn: parent; anchors.horizontalCenterOffset: 1; text: "▶"; font.family: Theme.font; font.pixelSize: 10; color: Theme.text }
                        }
                    }

                    // Borde de selección
                    Rectangle {
                        anchors.fill: frame
                        anchors.margins: -4
                        radius: 22
                        color: "transparent"
                        border.width: 3
                        border.color: Matugen.accent
                        opacity: card.isCurrent ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    MouseArea {
                        anchors.fill: frame
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.isCurrent ? root.apply(card.modelData.path) : strip.currentIndex = card.index
                    }
                }
            }

            // Nombre y ayuda
            ColumnLayout {
                anchors.top: strip.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                visible: root.items.length > 0

                readonly property var sel: root.items[strip.currentIndex] ?? null

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: parent.sel ? root.prettyName(parent.sel.path) : ""
                    font.family: Theme.font
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    color: Theme.text
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: parent.sel ? (parent.sel.type === "video" ? "Fondo animado" : "Imagen")
                                       + "  ·  " + (strip.currentIndex + 1) + " de " + root.items.length : ""
                    font.family: Theme.font
                    font.pixelSize: 12
                    color: Theme.text2
                }

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 14
                    spacing: 18
                    Repeater {
                        model: [["←  →", "moverse"], ["Enter", "aplicar"], ["Esc", "cerrar"]]
                        delegate: Row {
                            required property var modelData
                            spacing: 7
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: keyText.implicitWidth + 14
                                implicitHeight: 22
                                radius: 6
                                color: Theme.control
                                border.width: 1
                                border.color: Theme.border
                                Text { id: keyText; anchors.centerIn: parent; text: modelData[0]; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold; color: Theme.text }
                            }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; font.family: Theme.font; font.pixelSize: 12; color: Theme.text2 }
                        }
                    }
                }
            }
        }
    }
}
