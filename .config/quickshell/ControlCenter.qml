// Centro de control: panel bajo el reloj de waybar, en el monitor enfocado.
// Se abre/cierra con `qs ipc call controlcenter toggle` (on-click del reloj);
// se cierra al hacer clic fuera o con Esc.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Scope {
    id: root

    property bool open: false     // estado lógico
    property bool mapped: false   // ventana visible (incluye la animación de cierre)
    property var targetScreen: null
    property real closedAt: 0

    function show() {
        targetScreen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        unmapTimer.stop()
        mapped = true
        open = true
        dnd.refresh()
    }
    function hide() {
        if (!open) return
        open = false
        closedAt = Date.now()
        unmapTimer.restart()
    }
    function toggle() {
        if (open) hide()
        // Al pulsar el reloj con el panel abierto, el clic fuera ya lo cerró: no reabrir
        else if (Date.now() - closedAt > 300) show()
    }
    // Ejecuta un comando después de cerrar el panel (para que no salga en capturas)
    function runClosed(cmd) {
        hide()
        launcher.command = cmd
        launchTimer.restart()
    }

    IpcHandler {
        target: "controlcenter"
        function toggle(): void { root.toggle() }
        function open(): void { root.show() }
        function close(): void { root.hide() }
    }

    Timer { id: unmapTimer; interval: 220; onTriggered: root.mapped = false }
    Timer { id: launchTimer; interval: 250; onTriggered: launcher.startDetached() }
    Process { id: launcher }

    // ── Estado del sistema ──────────────────────────────────────────────
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source] }

    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var btConnected: bt ? bt.devices.values.filter(d => d.connected) : []

    // No molestar = notificaciones de dunst en pausa
    QtObject {
        id: dnd
        property bool on: false
        function refresh() { dndGet.running = true }
        function set(v) { on = v; dndSet.command = ["dunstctl", "set-paused", v ? "true" : "false"]; dndSet.running = true }
    }
    Process {
        id: dndGet
        command: ["dunstctl", "is-paused"]
        stdout: StdioCollector { onStreamFinished: dnd.on = text.trim() === "true" }
    }
    Process { id: dndSet }

    // ── Ventana ─────────────────────────────────────────────────────────
    PanelWindow {
        id: win
        visible: root.mapped
        screen: root.targetScreen

        anchors { top: true; right: true }
        margins { top: 6; right: 8 }
        exclusionMode: ExclusionMode.Normal   // se coloca bajo waybar sin reservar espacio
        exclusiveZone: 0
        implicitWidth: 360
        implicitHeight: panel.implicitHeight
        color: "transparent"

        WlrLayershell.namespace: "quickshell-controlcenter"   // blur: hypr/conf/rules.lua
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        HyprlandFocusGrab {
            windows: [win]
            active: root.open
            onCleared: root.hide()
        }

        Rectangle {
            id: panel
            width: parent.width
            implicitHeight: layout.implicitHeight + 2 * Theme.gap + 4
            radius: Theme.radius
            color: Theme.panel
            border.width: 1
            border.color: Theme.border

            // Aparece deslizándose desde la barra
            opacity: root.open ? 1 : 0
            scale: root.open ? 1 : 0.96
            transformOrigin: Item.TopRight
            transform: Translate { y: root.open ? 0 : -10; Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            focus: true
            Keys.onEscapePressed: root.hide()

            ColumnLayout {
                id: layout
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.gap + 2 }
                spacing: Theme.gap

                // ── Interruptores + energía ─────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.gap

                    Tile {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        hoverable: false

                        ColumnLayout {
                            width: parent.width
                            spacing: 10

                            CircleToggle {
                                icon: root.bt?.enabled ? "󰂯" : "󰂲"
                                label: "Bluetooth"
                                subtitle: !root.bt ? "No disponible"
                                        : !root.bt.enabled ? "Desactivado"
                                        : root.btConnected.length === 1 ? root.btConnected[0].name
                                        : root.btConnected.length > 1 ? root.btConnected.length + " dispositivos"
                                        : "Activado"
                                active: root.bt?.enabled ?? false
                                onClicked: if (root.bt) root.bt.enabled = !root.bt.enabled
                            }
                            CircleToggle {
                                icon: dnd.on ? "󰂛" : "󰂚"
                                label: "No molestar"
                                subtitle: dnd.on ? "Activado" : "Desactivado"
                                active: dnd.on
                                onClicked: dnd.set(!dnd.on)
                            }
                            CircleToggle {
                                readonly property bool micOn: !(root.source?.audio?.muted ?? true)
                                icon: micOn ? "󰍬" : "󰍭"
                                label: "Micrófono"
                                subtitle: micOn ? "Activado" : "Silenciado"
                                active: micOn
                                onClicked: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: Theme.gap

                        // Modo de energía: selector de tres segmentos
                        Tile {
                            Layout.fillWidth: true
                            hoverable: false

                            ColumnLayout {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: ["Ahorro", "Equilibrado", "Rendimiento"][PowerProfiles.profile] ?? "Energía"
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: Theme.text
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 30
                                    radius: 15
                                    color: Theme.control

                                    Rectangle {   // indicador que se desliza
                                        width: parent.width / 3
                                        height: parent.height
                                        radius: 15
                                        x: width * PowerProfiles.profile
                                        color: Matugen.accent
                                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    }

                                    Row {
                                        anchors.fill: parent
                                        Repeater {
                                            model: [
                                                { icon: "󰾆", profile: PowerProfile.PowerSaver },
                                                { icon: "󰾅", profile: PowerProfile.Balanced },
                                                { icon: "󰓅", profile: PowerProfile.Performance },
                                            ]
                                            delegate: Item {
                                                required property var modelData
                                                width: parent.width / 3
                                                height: parent.height
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.icon
                                                    font.family: Theme.iconFont
                                                    font.pixelSize: 17
                                                    color: PowerProfiles.profile === modelData.profile ? Matugen.accentText : Theme.text
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    enabled: modelData.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                                                    onClicked: PowerProfiles.profile = modelData.profile
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Accesos rápidos
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Theme.gap

                            Repeater {
                                model: [
                                    { icon: "󰹑", label: "Captura", cmd: [Quickshell.env("HOME") + "/.config/hypr/scripts/screenshot.sh"] },
                                    { icon: "󰸉", label: "Fondo", cmd: ["qs", "ipc", "call", "wallpapers", "open"] },
                                ]
                                delegate: Tile {
                                    id: quick
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    padding: 8
                                    implicitHeight: 58

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 3
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: quick.modelData.icon
                                            font.family: Theme.iconFont
                                            font.pixelSize: 21
                                            color: Theme.text
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: quick.modelData.label
                                            font.family: Theme.font
                                            font.pixelSize: 11
                                            color: Theme.text
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.runClosed(quick.modelData.cmd)
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Sonido ──────────────────────────────────────────────
                Tile {
                    Layout.fillWidth: true
                    hoverable: false

                    ColumnLayout {
                        width: parent.width
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Sonido"
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: Theme.text
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: Math.round((root.sink?.audio?.volume ?? 0) * 100) + "%"
                                font.family: Theme.font
                                font.pixelSize: 11
                                color: Theme.text2
                            }
                        }

                        LevelSlider {
                            Layout.fillWidth: true
                            value: root.sink?.audio?.volume ?? 0
                            muted: root.sink?.audio?.muted ?? false
                            icon: value < 0.34 ? "󰕿" : value < 0.67 ? "󰖀" : "󰕾"
                            mutedIcon: "󰝟"
                            onMoved: v => { if (root.sink?.audio) { root.sink.audio.muted = false; root.sink.audio.volume = v } }
                            onIconClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.sink?.description || root.sink?.nickname || root.sink?.name || ""
                            font.family: Theme.font
                            font.pixelSize: 11
                            color: Theme.text2
                            elide: Text.ElideRight
                        }
                    }
                }

                // ── Ahora suena ─────────────────────────────────────────
                MediaCard {
                    Layout.fillWidth: true
                    active: root.open
                }
            }
        }
    }
}
