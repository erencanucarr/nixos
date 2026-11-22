import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common

// Due notes (Notes.due), one card each, hung under the bar in the middle
// of the focused screen. They stay until "Tamam" or a snooze: a reminder
// that fades on its own is easy to miss. Built only while something is due
// (shell.qml).
PanelWindow {
    id: root

    readonly property int fs: 14
    readonly property int wt: 550

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "can-reminder"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors.top: true
    margins.top: Theme.barHeight + 10
    implicitWidth: 380
    implicitHeight: stack.implicitHeight + 8
    color: "transparent"

    Column {
        id: stack

        width: parent.width
        spacing: 8

        Repeater {
            model: Notes.due

            delegate: Surface {
                id: card

                required property var modelData

                width: stack.width
                height: body.implicitHeight + 2 * Theme.pad + 4
                opacity: 0

                Component.onCompleted: card.opacity = 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.anim
                    }
                }

                ColumnLayout {
                    id: body

                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: Theme.pad + 2
                        rightMargin: Theme.pad + 2
                    }
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        BarText {
                            text: String.fromCodePoint(0xF009A) // bell
                            font.pixelSize: root.fs + 5
                            color: Theme.warm
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            BarText {
                                text: card.modelData.time ? `Hatırlatma · ${card.modelData.time}` : "Hatırlatma · bugün"
                                font.pixelSize: root.fs - 3
                                weight: root.wt
                                color: Theme.dim
                            }

                            BarText {
                                Layout.fillWidth: true
                                text: card.modelData.text
                                wrapMode: Text.Wrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                                font.pixelSize: root.fs
                                weight: root.wt
                                color: Theme.bright
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Pick {
                            Layout.preferredWidth: 1
                            implicitHeight: 30
                            textSize: root.fs - 2
                            weight: root.wt
                            label: "10 dk ertele"
                            align: Text.AlignHCenter
                            onClicked: Notes.snooze(card.modelData.date, card.modelData.id, 10)
                        }
                        Pick {
                            Layout.preferredWidth: 1
                            implicitHeight: 30
                            textSize: root.fs - 2
                            weight: root.wt
                            label: "1 sa ertele"
                            align: Text.AlignHCenter
                            onClicked: Notes.snooze(card.modelData.date, card.modelData.id, 60)
                        }
                        Pick {
                            Layout.preferredWidth: 1
                            implicitHeight: 30
                            textSize: root.fs - 2
                            weight: root.wt
                            label: "Tamam"
                            align: Text.AlignHCenter
                            current: true
                            onClicked: Notes.dismiss(card.modelData.id)
                        }
                    }
                }
            }
        }
    }
}
