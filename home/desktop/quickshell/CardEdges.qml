import QtQuick

// The rest of a bar card's edge (after xeome's CardEdges.qml), for a
// Rectangle that already draws its fill and a 1px Theme.line border: a dark
// ring one pixel outside it and a highlight inside its top edge.
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

    // A rounded ring cut to its top part, so it bends with the corners and
    // stops before the sides.
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
