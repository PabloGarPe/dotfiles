// Deslizador grueso estilo macOS: el icono va dentro de la pista.
// Arrastrar o hacer scroll cambia el valor; clic en el icono = silenciar.
import QtQuick

Item {
    id: slider

    property real value: 0          // 0..1
    property bool muted: false
    property string icon
    property string mutedIcon: icon
    signal moved(real value)
    signal iconClicked

    implicitHeight: 28

    readonly property real shown: muted ? 0 : Math.max(0, Math.min(1, value))

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.control

        Rectangle {
            id: fill
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            // Nunca más estrecho que el círculo del icono
            width: Math.max(track.height, track.width * slider.shown)
            radius: track.radius
            color: Theme.text
            opacity: slider.muted ? 0.35 : 1
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
    }

    Text {
        id: iconText
        width: track.height
        height: track.height
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: slider.muted ? slider.mutedIcon : slider.icon
        font.family: Theme.iconFont
        font.pixelSize: 14
        color: "#1c1c1e"
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        property bool onIcon: false

        function set(x) { slider.moved(Math.max(0, Math.min(1, x / width))) }

        onPressed: m => {
            onIcon = m.x < track.height
            if (!onIcon) set(m.x)
        }
        onPositionChanged: m => { if (pressed && !onIcon) set(m.x) }
        onClicked: m => { if (onIcon) slider.iconClicked() }
        onWheel: w => slider.moved(Math.max(0, Math.min(1, slider.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
