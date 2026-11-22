import QtQuick

Item {
    id: root

    property real radius: parent.radius

    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: root.radius + 1
        color: "transparent"
        border.width: 1
        border.color: Theme.ring
    }

    Item {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 1
        }
        height: Math.max(1, root.radius)
        clip: true

        Rectangle {
            width: parent.width
            height: parent.height * 3
            radius: Math.max(0, root.radius - 1)
            color: "transparent"
            border.width: 1
            border.color: Theme.lift
        }
    }
}
