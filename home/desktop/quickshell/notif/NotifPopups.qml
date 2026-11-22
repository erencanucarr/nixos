import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common

PanelWindow {
    id: root

    readonly property int maxVisible: 5

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    Component.onCompleted: root.screen = root.screen

    WlrLayershell.namespace: "can-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors {
        top: true
        right: true
    }
    margins.top: Theme.barHeight + 8
    implicitWidth: 320 + 12
    implicitHeight: Math.max(1, col.implicitHeight)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {
        item: col
    }

    Column {
        id: col

        width: 320
        spacing: 6

        add: Transition {
            NumberAnimation {
                property: "x"
                from: 12
                duration: Theme.anim
                easing.type: Theme.ease
            }
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Theme.anim
                easing.type: Theme.ease
            }
        }
        move: Transition {
            NumberAnimation {
                property: "y"
                duration: Theme.anim
                easing.type: Theme.ease
            }
            NumberAnimation {
                property: "opacity"
                to: 1
                duration: Theme.anim
                easing.type: Theme.ease
            }
        }

        Repeater {
            model: ScriptModel {
                values: Notifs.popups
            }

            delegate: NotifCard {
                id: card

                required property var modelData
                required property int index

                visible: card.index < root.maxVisible
                notif: modelData
                onDismissed: Notifs.drop(card.modelData)

                Timer {
                    interval: Notifs.timeout(card.modelData)
                    running: interval > 0 && card.visible && !card.hovered
                    onTriggered: Notifs.drop(card.modelData)
                }

                Connections {
                    target: card.modelData

                    function onClosed(): void {
                        Notifs.drop(card.modelData);
                    }
                }
            }
        }

        Surface {
            width: parent.width
            implicitHeight: 26
            visible: Notifs.popups.length > root.maxVisible

            BarText {
                anchors.centerIn: parent
                text: `+${Notifs.popups.length - root.maxVisible} bildirim daha`
                font.pixelSize: Theme.small
                weight: 550
                color: Theme.dim
            }
        }
    }
}
