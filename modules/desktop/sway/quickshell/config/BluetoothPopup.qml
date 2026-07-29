import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: bluetoothShade

    required property var modelData
    required property var rootRef

    screen: modelData
    WlrLayershell.namespace: "quickshell-bluetooth"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; left: true; right: true; bottom: true }
    margins { top: 0 }
    color: "transparent"
    visible: rootRef.bluetoothOpen

    MouseArea {
        anchors.fill: parent
        onClicked: rootRef.bluetoothOpen = false
    }

    Rectangle {
        id: panel
        x: parent.width - width - 12
        y: 0
        width: 400
        height: 430
        color: rootRef.chip
        border { color: "#8A8A8A"; width: 2 }
        radius: 7
        focus: visible

        Keys.onEscapePressed: event => {
            rootRef.bluetoothOpen = false
            event.accepted = true
        }

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "BLUETOOTH"
                    color: rootRef.accent
                    font { family: rootRef.fontFamily; pixelSize: 20; weight: Font.Bold }
                }
                Rectangle {
                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 28
                    color: rootRef.bluetoothPowered ? rootRef.accent : "transparent"
                    border { color: rootRef.accent; width: 1 }
                    radius: 5
                    Text {
                        anchors.centerIn: parent
                        text: rootRef.bluetoothPowered ? "ON" : "OFF"
                        color: rootRef.bluetoothPowered ? rootRef.bg : rootRef.fg
                        font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                    }
                    MouseArea { anchors.fill: parent; onClicked: rootRef.toggleBluetoothPower() }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootRef.line }

            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: "PAIRED DEVICES"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
                Text {
                    text: "REFRESH"
                    color: refreshArea.containsMouse ? rootRef.accent : rootRef.muted
                    font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold }
                    MouseArea { id: refreshArea; anchors.fill: parent; hoverEnabled: true; onClicked: rootRef.refreshBluetooth() }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 5
                model: rootRef.bluetoothDevices

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 48
                    color: modelData.connected ? rootRef.chipOn : "transparent"
                    border { color: modelData.connected ? rootRef.accent : rootRef.line; width: 1 }
                    radius: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10
                        Text { text: "󰂯"; color: modelData.connected ? rootRef.accent : rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 18; weight: Font.Bold } }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { Layout.fillWidth: true; text: modelData.name; color: rootRef.accent; elide: Text.ElideRight; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
                            Text { text: modelData.connected ? "CONNECTED" : "PAIRED"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold } }
                        }
                        Text { text: modelData.connected ? "DISCONNECT" : "CONNECT"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold } }
                    }

                    MouseArea { anchors.fill: parent; onClicked: rootRef.toggleBluetoothDevice(modelData) }
                }

                Text {
                    anchors.centerIn: parent
                    visible: rootRef.bluetoothDevices.length === 0
                    text: "NO PAIRED DEVICES"
                    color: rootRef.muted
                    font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootRef.line }
            Text { text: "Click a device to connect or disconnect"; color: rootRef.muted; font { family: rootRef.fontFamily; pixelSize: 9 } }
        }
    }
}
