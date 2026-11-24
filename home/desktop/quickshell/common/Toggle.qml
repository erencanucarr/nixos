import QtQuick

Rectangle {
    id: root

    property bool on: false

    signal toggled

    implicitWidth: 36
    implicitHeight: 20
    radius: height / 2
    color: root.on ? Theme.text : "transparent"
    border.width: 1
    border.color: root.on ? Theme.text : Theme.edge

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim
        }
    }

    Rectangle {
        y: 3
        x: root.on ? root.width - width - 3 : 3
        width: 14
        height: 14
        radius: 7
        color: root.on ? Theme.ground : Theme.dim

        Behavior on x {
            NumberAnimation {
                duration: Theme.anim
                easing.type: Theme.ease
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
