import Quickshell
import Quickshell.Services.UPower
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    required property var modelData
    required property var rootRef

    readonly property var dev: {
        const list = UPower.devices ? UPower.devices.values : []
        for (const d of list) {
            if (d && d.nativePath && d.nativePath.indexOf("battery_") === 0)
                return d
        }
        return UPower.displayDevice
    }
    readonly property bool hasBattery: dev && dev.isPresent
    readonly property int percent: hasBattery ? Math.round(dev.percentage * 100) : 0
    readonly property bool charging: hasBattery && (
        dev.state === UPowerDeviceState.Charging ||
        dev.state === UPowerDeviceState.FullyCharged)
    readonly property int secondsRemaining: {
        if (!hasBattery) return 0
        const value = charging ? dev.timeToFull : dev.timeToEmpty
        return Number(value) || 0
    }
    readonly property string timeLabel: {
        if (!hasBattery) return "no battery"
        if (dev.state === UPowerDeviceState.FullyCharged) return "fully charged"
        if (secondsRemaining <= 0) return "estimating"
        const hours = Math.floor(secondsRemaining / 3600)
        const minutes = Math.round((secondsRemaining % 3600) / 60)
        const text = (hours > 0 ? hours + "h " : "") + minutes + "m"
        return charging ? text + " to full" : text + " remaining"
    }
    readonly property string stateLabel: {
        if (!hasBattery) return "unknown"
        if (dev.state === UPowerDeviceState.Charging) return "charging"
        if (dev.state === UPowerDeviceState.Discharging) return "discharging"
        if (dev.state === UPowerDeviceState.FullyCharged) return "full"
        if (dev.state === UPowerDeviceState.PendingCharge) return "pending charge"
        if (dev.state === UPowerDeviceState.PendingDischarge) return "pending discharge"
        return "idle"
    }

    screen: modelData
    WlrLayershell.namespace: "quickshell-battery-shade"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; left: true; right: true; bottom: true }
    margins { top: 0 }
    color: "transparent"
    visible: rootRef.batteryOpen

    MouseArea {
        anchors.fill: parent
        onClicked: rootRef.batteryOpen = false
    }

    Rectangle {
        id: batteryBox
        x: parent.width - width - 12
        y: 0
        width: 360
        height: 352
        color: rootRef.chip
        border { color: "#8A8A8A"; width: 2 }
        radius: 7
        focus: visible
        Keys.onEscapePressed: event => {
            rootRef.batteryOpen = false
            event.accepted = true
        }
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    color: rootRef.chipOn
                    border { color: rootRef.line; width: 1 }
                    radius: 5
                    Text {
                        anchors.centerIn: parent
                        text: charging ? "󰂄" : "󰁹"
                        color: rootRef.accent
                        font { family: rootRef.fontFamily; pixelSize: 22; weight: Font.Bold }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: hasBattery ? percent + "%" : "Battery"
                        color: rootRef.accent
                        font { family: rootRef.fontFamily; pixelSize: 22; weight: Font.Bold }
                    }
                    Text {
                        text: stateLabel + " · " + timeLabel
                        color: rootRef.fg
                        font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 9
                color: rootRef.line
                radius: 5
                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * Math.min(1, Math.max(0, percent / 100))
                    height: parent.height
                    radius: 5
                    color: percent <= 15 && !charging ? rootRef.danger : rootRef.accent
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 16
                rowSpacing: 7

                Text { text: "State"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 12 } }
                Text { text: stateLabel; color: rootRef.accent; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true; font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold } }
                Text { text: charging ? "Until full" : "Remaining"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 12 } }
                Text { text: timeLabel; color: rootRef.accent; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true; font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold } }
                Text { text: "Device"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 12 } }
                Text { text: hasBattery && dev.model ? dev.model : "display battery"; color: rootRef.fg; horizontalAlignment: Text.AlignRight; elide: Text.ElideMiddle; Layout.fillWidth: true; font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold } }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootRef.line }

            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: "POWER PROFILE"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
                Text { text: rootRef.powerProfile || "unknown"; color: rootRef.accent; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Repeater {
                    model: [
                        { id: "performance", label: "Performance", icon: "󱐋" },
                        { id: "balanced", label: "Balanced", icon: "" },
                        { id: "power-saver", label: "Power Saver", icon: "" },
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        property bool hover: false
                        readonly property bool active: rootRef.powerProfile === modelData.id

                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        color: active ? rootRef.chipOn : (hover ? rootRef.chipHover : "transparent")
                        border { color: active ? rootRef.accent : rootRef.line; width: 1 }
                        radius: 7

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8
                            Text { text: modelData.icon; color: rootRef.accent; font { family: rootRef.fontFamily; pixelSize: 14; weight: Font.Bold } }
                            Text { Layout.fillWidth: true; text: modelData.label; color: active ? rootRef.accent : rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold } }
                            Text { text: active ? "active" : "set"; color: active ? rootRef.accent : rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: parent.hover = true
                            onExited: parent.hover = false
                            onClicked: rootRef.setPowerProfile(modelData.id)
                        }
                    }
                }
            }
        }
    }
}
