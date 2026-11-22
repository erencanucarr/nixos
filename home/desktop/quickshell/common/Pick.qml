import QtQuick
import QtQuick.Layouts
import qs.common

// A menu row you press to choose something (after xeome's Pick.qml); the
// current choice and the alternatives are the same control, so a stack of
// them reads like an open select. It sits on `raised`, hence hoverRaised
// and `edge`.
Rectangle {
    id: root

    required property string label
    property string suffix: ""
    property bool current: false
    property bool selectable: true
    property int align: Text.AlignLeft
    // The audio menu sets xeome's sizes (30px rows, 12px text at 550).
    property int textSize: Theme.small
    property int weight: 0

    signal clicked

    Layout.fillWidth: true
    implicitHeight: 26
    radius: Theme.radius
    color: root.current ? Theme.sel : ma.containsMouse ? Theme.hoverRaised : "transparent"
    border.width: 1
    border.color: Theme.edge

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim
            easing.type: Theme.ease
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 9
            rightMargin: 9
        }
        spacing: 6

        BarText {
            Layout.fillWidth: true
            text: root.label
            elide: Text.ElideRight
            horizontalAlignment: root.align
            font.pixelSize: root.textSize
            weight: root.weight
            color: root.current ? Theme.bright : Theme.text
        }

        BarText {
            visible: root.suffix !== ""
            text: root.suffix
            font.pixelSize: root.textSize
            weight: root.weight
            color: root.current ? Theme.text : Theme.dim
        }
    }

    MouseArea {
        id: ma

        anchors.fill: parent
        hoverEnabled: true
        // Off when there is nothing else to pick, so the row shows no hover.
        enabled: root.selectable
        onClicked: root.clicked()
    }
}
