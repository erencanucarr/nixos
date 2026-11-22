import QtQuick

Rectangle {
    id: root

    property bool selected: false
    property int minWidth: 0
    property bool bordered: true
    default property alias content: row.data

    signal clicked(int button)
    signal scrolled(int delta)

    readonly property bool hovered: area.containsMouse

    implicitWidth: Math.max(minWidth, implicitHeight, row.implicitWidth + 2 * (Theme.pad - 2))
    implicitHeight: Theme.barHeight - 2 * Theme.gap

    radius: bordered ? Theme.radius : 0
    color: selected ? Theme.sel : hovered ? Theme.hover : Theme.card
    border.width: bordered ? 1 : 0
    border.color: Theme.line

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim
            easing.type: Easing.OutCubic
        }
    }

    data: [
        CardEdges {
            visible: root.bordered
        },

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 5
        },

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            onClicked: e => root.clicked(e.button)
            onWheel: e => root.scrolled(e.angleDelta.y)
        }
    ]
}
