// Tarjeta de "Ahora suena" (MPRIS): carátula, título, progreso y controles.
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets

Tile {
    id: card

    // El que esté sonando; si no, el primero que haya
    readonly property var players: Mpris.players.values
    readonly property MprisPlayer player: players.find(p => p.isPlaying) ?? players[0] ?? null
    property bool active: true   // el panel está abierto: refrescar la posición

    visible: player !== null
    hoverable: false

    // MPRIS no notifica la posición mientras avanza: hay que pedirla
    Timer {
        running: card.active && card.player?.isPlaying === true
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: card.player.positionChanged()
    }

    function fmt(s) {
        if (!isFinite(s) || s < 0) return "0:00"
        s = Math.floor(s)
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    ColumnLayout {
        width: parent.width
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ClippingRectangle {
                implicitWidth: 52
                implicitHeight: 52
                radius: 10
                color: Theme.control

                Image {
                    anchors.fill: parent
                    source: card.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(104, 104)
                }
                Text {
                    anchors.centerIn: parent
                    visible: !(card.player?.trackArtUrl)
                    text: "󰝚"
                    font.family: Theme.iconFont
                    font.pixelSize: 22
                    color: Theme.text2
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: card.player?.trackTitle || "Sin título"
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Theme.text
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: card.player?.trackArtist || card.player?.identity || ""
                    font.family: Theme.font
                    font.pixelSize: 12
                    color: Theme.text2
                    elide: Text.ElideRight
                }
            }

            Repeater {
                model: [
                    { icon: "󰒮", act: "prev", size: 18 },
                    { icon: card.player?.isPlaying ? "󰏤" : "󰐊", act: "play", size: 24 },
                    { icon: "󰒭", act: "next", size: 18 },
                ]
                delegate: Rectangle {
                    required property var modelData
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15
                    color: btn.containsMouse ? Theme.control : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        font.family: Theme.iconFont
                        font.pixelSize: modelData.size
                        color: Theme.text
                    }
                    MouseArea {
                        id: btn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const p = card.player
                            if (modelData.act === "prev") p.previous()
                            else if (modelData.act === "next") p.next()
                            else p.togglePlaying()
                        }
                    }
                }
            }
        }

        // Progreso (clic para saltar, si el reproductor lo permite)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: (card.player?.lengthSupported ?? false) && card.player.length > 0

            Rectangle {
                id: bar
                Layout.fillWidth: true
                implicitHeight: 4
                radius: 2
                color: Theme.control

                Rectangle {
                    height: parent.height
                    radius: 2
                    color: Matugen.accent
                    width: card.player && card.player.length > 0
                           ? parent.width * Math.min(1, card.player.position / card.player.length) : 0
                    Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    enabled: card.player?.canSeek ?? false
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: m => card.player.position = card.player.length * Math.max(0, Math.min(1, (m.x - 6) / bar.width))
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: card.fmt(card.player?.position ?? 0)
                    font.family: Theme.font; font.pixelSize: 10; color: Theme.text2
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: card.fmt(card.player?.length ?? 0)
                    font.family: Theme.font; font.pixelSize: 10; color: Theme.text2
                }
            }
        }
    }
}
