// Interruptor redondo con texto (Bluetooth, No molestar…), como en macOS.
import QtQuick
import QtQuick.Layouts

Item {
    id: toggle

    property string icon
    property string label
    property string subtitle
    property bool active
    signal clicked

    implicitHeight: 34
    Layout.fillWidth: true

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            implicitWidth: 32
            implicitHeight: 32
            radius: 16
            color: toggle.active ? Matugen.accent : Theme.control
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: toggle.icon
                font.family: Theme.iconFont
                font.pixelSize: 15
                color: toggle.active ? Matugen.accentText : Theme.text
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: toggle.label
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.text
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: toggle.subtitle
                visible: text !== ""
                font.family: Theme.font
                font.pixelSize: 11
                color: Theme.text2
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: toggle.clicked()
    }
}
