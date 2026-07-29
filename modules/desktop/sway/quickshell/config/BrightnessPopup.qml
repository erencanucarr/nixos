import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: brightnessShade

    required property var modelData
    required property var rootRef

    screen: modelData
    WlrLayershell.namespace: "quickshell-brightness"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; left: true; right: true; bottom: true }
    margins { top: 0 }
    color: "transparent"
    visible: rootRef.brightnessOpen

    MouseArea {
        anchors.fill: parent
        onClicked: rootRef.brightnessOpen = false
    }

    Rectangle {
        id: panel
        x: parent.width - width - 12
        y: 0
        width: 340
        height: 190
        color: "#F50D0D0D"
        border { color: "#8A8A8A"; width: 1 }
        focus: visible

        Keys.onEscapePressed: event => {
            rootRef.brightnessOpen = false
            event.accepted = true
        }

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "󰃠  BRIGHTNESS"
                    color: "#FFFFFF"
                    font { family: rootRef.fontFamily; pixelSize: 15; weight: Font.Bold }
                }
                Text {
                    text: rootRef.brightnessPercent + "%"
                    color: "#FFFFFF"
                    font { family: rootRef.fontFamily; pixelSize: 20; weight: Font.Bold }
                }
            }

            Rectangle {
                id: slider
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                color: "#1E1E22"
                border { color: "#333337"; width: 1 }

                Rectangle {
                    width: parent.width * rootRef.brightnessPercent / 100
                    height: parent.height
                    color: "#FFFFFF"
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: mouse => rootRef.setBrightnessPercent(Math.round(mouse.x / width * 100))
                    onPositionChanged: mouse => {
                        if (pressed) rootRef.setBrightnessPercent(Math.round(mouse.x / width * 100))
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: ["-10", "-5", "+5", "+10"]
                    delegate: Rectangle {
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        color: buttonArea.containsMouse ? "#2E2E30" : "#141416"
                        border { color: "#333337"; width: 1 }
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: "#FFFFFF"
                            font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                        }
                        MouseArea {
                            id: buttonArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: rootRef.setBrightnessPercent(rootRef.brightnessPercent + parseInt(modelData))
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: "Click slider to adjust"; color: "#777777"; font { family: rootRef.fontFamily; pixelSize: 9 } }
                Text { text: "ESC  CLOSE"; color: "#777777"; font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold } }
            }
        }
    }
}
