// Bloque translúcido del centro de control; se ilumina al pasar el ratón.
import QtQuick

Rectangle {
    id: tile

    default property alias content: box.data
    property int padding: 12
    property bool hoverable: true
    readonly property bool hovered: hover.hovered

    implicitHeight: box.childrenRect.height + 2 * padding
    radius: Theme.tileRadius
    color: hoverable && hovered ? Theme.tileHover : Theme.tile
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.05)

    Behavior on color { ColorAnimation { duration: 150 } }

    HoverHandler { id: hover }

    Item {
        id: box
        anchors.fill: parent
        anchors.margins: tile.padding
    }
}
