import QtQuick

// The rounded card every bar module sits in (after xeome's BarModule.qml),
// scaled down to the 30px bar: a nearly clear fill, a hairline border and
// CardEdges. Children go into a centred Row.
Rectangle {
    id: root

    // Something open or switched on (the drawer, the power menu) is `sel`.
    property bool selected: false
    // Keeps the row from resizing when a label changes width. Single-glyph
    // modules leave it at 0 so they come out square.
    property int minWidth: 0
    // False inside a connected strip, which is bordered as a group.
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

    // Assigned to `data` explicitly: the default property is aliased to
    // row.data, so bare children here would land inside the row.
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
