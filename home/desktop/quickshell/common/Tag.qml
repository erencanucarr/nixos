import QtQuick

Rectangle {
    id: root

    property string text
    property color tone: Theme.text
    property bool dot: false
    property bool accent: false
    property bool clickable: false

    signal clicked

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 24
    radius: height / 2
    color: root.accent ? Qt.alpha(root.tone, ma.containsMouse ? 0.16 : 0.1) : (ma.containsMouse ? Theme.selRaised : Theme.hoverRaised)
    border.width: 1
    border.color: root.accent ? Qt.alpha(root.tone, 0.35) : Theme.edge

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7

        Rectangle {
            visible: root.dot
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            radius: 3
            color: root.tone
        }

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.pixelSize: 10
            weight: 600
            color: root.tone
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: root.clickable
        enabled: root.clickable
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
