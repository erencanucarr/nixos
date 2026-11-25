import QtQuick

BarText {
    id: root

    property int reach: 4
    property color hoverColor: Theme.bright
    readonly property bool hovered: ma.containsMouse

    signal clicked

    color: root.hovered ? root.hoverColor : Theme.dim

    MouseArea {
        id: ma

        anchors.fill: parent
        anchors.margins: -root.reach
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
