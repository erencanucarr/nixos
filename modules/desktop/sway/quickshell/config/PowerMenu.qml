import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: powerShade

    required property var modelData
    required property var rootRef

    readonly property var actions: [
        { id: "shutdown", icon: "⏻", label: "Shutdown", detail: "Power off system" },
        { id: "reboot", icon: "", label: "Reboot", detail: "Restart system" },
        { id: "lock", icon: "", label: "Lock", detail: "Lock screen" },
        { id: "logout", icon: "󰗽", label: "Logout", detail: "Exit Sway session" },
        { id: "sleep", icon: "󰤄", label: "Sleep", detail: "Suspend system" }
    ]

    function runAction(action) {
        rootRef.powerOpen = false
        if (action === "shutdown") Quickshell.execDetached(["systemctl", "poweroff"])
        else if (action === "reboot") Quickshell.execDetached(["systemctl", "reboot"])
        else if (action === "lock") Quickshell.execDetached(["swaylock", "-f"])
        else if (action === "logout") Quickshell.execDetached(["swaymsg", "exit"])
        else if (action === "sleep") Quickshell.execDetached(["systemctl", "suspend"])
    }

    screen: modelData
    WlrLayershell.namespace: "quickshell-power-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; left: true; right: true; bottom: true }
    margins { top: 34 }
    color: "transparent"
    visible: rootRef.powerOpen

    MouseArea {
        anchors.fill: parent
        onClicked: rootRef.powerOpen = false
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 440
        height: 390
        color: rootRef.chip
        border { color: "#8A8A8A"; width: 2 }
        radius: 8
        focus: visible
        Keys.onEscapePressed: event => {
            rootRef.powerOpen = false
            event.accepted = true
        }
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "POWER"
                    color: rootRef.accent
                    font { family: rootRef.fontFamily; pixelSize: 22; weight: Font.Bold }
                }
                Text {
                    text: "MOD4 + P"
                    color: rootRef.muted
                    font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootRef.line }

            Text {
                text: "SESSION CONTROL"
                color: rootRef.fg
                font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 7
                columnSpacing: 7

                Repeater {
                    model: powerShade.actions
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        color: hoverArea.containsMouse ? rootRef.chipHover : "#0A0A0A"
                        border { color: rootRef.line; width: 1 }
                        radius: 5

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 11
                            anchors.rightMargin: 9
                            spacing: 9
                            Text {
                                text: modelData.icon
                                color: modelData.id === "shutdown" || modelData.id === "reboot" ? rootRef.danger : rootRef.accent
                                font { family: rootRef.fontFamily; pixelSize: 17; weight: Font.Bold }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text { text: modelData.label; color: rootRef.accent; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
                                Text { text: modelData.detail; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 9 } }
                            }
                        }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: powerShade.runAction(modelData.id)
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootRef.line }

            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: "POWER PROFILE"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
                Text { text: rootRef.powerProfile || "unknown"; color: rootRef.accent; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 5
                Repeater {
                    model: [
                        { id: "performance", label: "PERF" },
                        { id: "balanced", label: "BALANCED" },
                        { id: "power-saver", label: "SAVE" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: rootRef.powerProfile === modelData.id ? rootRef.accent : "transparent"
                        border { color: rootRef.powerProfile === modelData.id ? rootRef.accent : rootRef.line; width: 1 }
                        radius: 5
                        Text { anchors.centerIn: parent; text: modelData.label; color: rootRef.powerProfile === modelData.id ? rootRef.bg : rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold } }
                        MouseArea { anchors.fill: parent; onClicked: rootRef.setPowerProfile(modelData.id) }
                    }
                }
            }
        }
    }
}
