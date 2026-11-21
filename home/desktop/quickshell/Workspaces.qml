import QtQuick
import Quickshell
import Quickshell.Hyprland

// This screen's workspaces in one card of hairline-divided buttons (after
// xeome's Workspaces.qml): the shown one filled with `sel` and bright, an
// urgent one hot.
Rectangle {
    id: root

    required property var screen

    readonly property var list: [...Hyprland.workspaces.values].filter(w => w.id > 0 && w.monitor?.name === root.screen.name).sort((a, b) => a.id - b.id)

    implicitWidth: row.implicitWidth + 2
    implicitHeight: Theme.barHeight - 2 * Theme.gap
    color: Theme.card
    radius: Theme.radius
    border.width: 1
    border.color: Theme.line

    CardEdges {}

    Row {
        id: row
        anchors.fill: parent
        anchors.margins: 1

        Repeater {
            model: root.list

            delegate: Rectangle {
                id: btn

                required property var modelData
                required property int index

                readonly property bool shown: modelData.active
                readonly property bool last: index === root.list.length - 1

                width: Math.max(28, label.implicitWidth + 16)
                height: row.height
                color: shown ? Theme.sel : area.containsMouse ? Theme.hover : "transparent"

                // The ends round themselves, one less than the card's radius
                // inside its 1px border.
                topLeftRadius: index === 0 ? Theme.radius - 1 : 0
                bottomLeftRadius: index === 0 ? Theme.radius - 1 : 0
                topRightRadius: last ? Theme.radius - 1 : 0
                bottomRightRadius: last ? Theme.radius - 1 : 0

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.anim
                    }
                }

                BarText {
                    id: label
                    anchors.centerIn: parent
                    // Other numbers stay `text`, not `dim`: you navigate by them.
                    text: btn.modelData.name
                    color: btn.modelData.urgent ? Theme.hot : btn.shown ? Theme.bright : Theme.text
                    font.weight: btn.shown ? Font.DemiBold : Font.Normal
                }

                Rectangle {
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 1
                    visible: !btn.last
                    color: Theme.line
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: btn.modelData.activate()
                }
            }
        }
    }
}
