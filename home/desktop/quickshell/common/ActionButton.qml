import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property string text
    property bool primary: false

    signal clicked

    Layout.fillWidth: true
    implicitHeight: 34
    radius: Theme.radius + 2
    opacity: root.enabled ? 1 : 0.45
    color: root.primary ? (ma.containsMouse ? Theme.bright : Theme.text) : (ma.containsMouse ? Theme.selRaised : Theme.hoverRaised)
    border.width: root.primary ? 0 : 1
    border.color: Theme.edge

    BarText {
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: 12
        weight: 650
        color: root.primary ? Theme.ground : Theme.text
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
