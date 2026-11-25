import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common

Item {
    id: root

    required property int workspaceId
    required property var monitor
    property bool shown: false
    property bool current: false
    property bool dropTarget: false

    readonly property var windows: Hyprland.toplevels.values.filter(t => t.workspace?.id === root.workspaceId)
    readonly property real ratio: width / Math.max(1, monitor?.width ?? 1920)

    signal clicked

    ClippingRectangle {
        id: card

        anchors.fill: parent
        radius: 8
        color: Theme.ground

        Repeater {
            model: root.windows

            delegate: ClippingRectangle {
                id: mini

                required property var modelData
                readonly property var ipc: modelData.lastIpcObject ?? {}

                x: ((ipc.at?.[0] ?? 0) - (root.monitor?.x ?? 0)) * root.ratio
                y: ((ipc.at?.[1] ?? 0) - (root.monitor?.y ?? 0)) * root.ratio
                width: (ipc.size?.[0] ?? 0) * root.ratio
                height: (ipc.size?.[1] ?? 0) * root.ratio
                radius: 3
                color: Theme.raised
                border.width: 1
                border.color: Theme.rule

                ScreencopyView {
                    anchors.fill: parent
                    captureSource: mini.modelData.wayland ?? null
                    live: false
                    constraintSize: Qt.size(mini.width, mini.height)
                }
            }
        }

        BarText {
            anchors {
                left: parent.left
                bottom: parent.bottom
                margins: 6
            }
            text: root.workspaceId
            font.weight: Font.DemiBold
            color: root.shown ? Theme.bright : Theme.dim
            style: Text.Outline
            styleColor: Theme.ground
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: card.radius
        color: root.dropTarget ? Theme.sel : "transparent"
        border.width: root.shown || root.dropTarget ? 2 : 1
        border.color: root.shown || root.dropTarget ? Theme.bright : ma.containsMouse ? Theme.dim : Theme.rule

        Behavior on border.color {
            ColorAnimation {
                duration: Theme.anim
            }
        }
    }

    Rectangle {
        visible: root.current && !root.shown
        anchors {
            top: parent.top
            right: parent.right
            margins: 6
        }
        width: 6
        height: 6
        radius: 3
        color: Theme.text
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
