import QtQuick
import qs.common

// A mode or tool in a toolbar pill (Shot, ShotEditor), after xeome's Chip.qml.
// Selected is `sel`, never a colour. It sits on a Surface, so hover is the
// `raised` variant.
Rectangle {
    id: chip

    property alias text: label.text
    property bool on

    signal clicked

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 30
    radius: Theme.radius
    color: chip.on ? Theme.sel : chipMa.containsMouse ? Theme.hoverRaised : "transparent"

    BarText {
        id: label

        anchors.centerIn: parent
        color: chip.on ? Theme.bright : Theme.dim
        font.weight: chip.on ? Font.DemiBold : Font.Medium
    }

    MouseArea {
        id: chipMa

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
