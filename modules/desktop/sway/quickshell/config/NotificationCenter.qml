import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: notifShade

    required property var modelData
    required property var rootRef
    required property var notificationServer

    screen: modelData
    WlrLayershell.namespace: "quickshell-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; left: true; right: true; bottom: true }
    margins { top: 0 }
    color: "transparent"
    visible: rootRef.notifOpen

    MouseArea {
        anchors.fill: parent
        onClicked: rootRef.notifOpen = false
    }

    Rectangle {
        id: panel
        x: parent.width - width - 10
        y: 0
        width: 420
        height: Math.min(parent.height - 20, 520)
        color: "#0D0D0D"
        border { color: "#FFFFFF"; width: 1 }
        focus: visible
        Keys.onEscapePressed: event => {
            rootRef.notifOpen = false
            event.accepted = true
        }
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "󰂚  NOTIFICATIONS"
                    color: "#FFFFFF"
                    font { family: rootRef.fontFamily; pixelSize: 16; weight: Font.Bold }
                }
                Rectangle {
                    Layout.preferredWidth: clearLabel.implicitWidth + 20
                    Layout.preferredHeight: 28
                    color: clearArea.containsMouse ? "#2E2E30" : "transparent"
                    border { color: "#333337"; width: 1 }
                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "󰎟  CLEAR"
                        color: "#FFFFFF"
                        font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                    }
                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            for (const n of notificationServer.trackedNotifications.values.slice()) n.dismiss()
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#333337" }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                color: dndArea.containsMouse ? "#202022" : "transparent"
                border { color: "#333337"; width: 1 }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "DO NOT DISTURB"
                    color: "#FFFFFF"
                    font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 20
                    color: "transparent"
                    border { color: "#555555"; width: 1 }
                    Rectangle {
                        x: rootRef.dnd ? 22 : 2
                        y: 2
                        width: 16
                        height: 16
                        color: rootRef.dnd ? "#FFFFFF" : "#777777"
                        Behavior on x { NumberAnimation { duration: 180 } }
                    }
                }
                MouseArea {
                    id: dndArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: rootRef.dnd = !rootRef.dnd
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: notificationServer.trackedNotifications

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    implicitHeight: Math.max(66, notificationColumn.implicitHeight + 24)
                    color: notificationArea.containsMouse ? "#2E2E30" : "#141416"
                    border { color: "#333337"; width: 1 }

                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: 2
                        color: "#FFFFFF"
                        opacity: modelData.urgency === NotificationUrgency.Critical ? 1 : 0.35
                    }

                    MouseArea {
                        id: notificationArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            const action = modelData.actions.find(a => a.identifier === "default")
                            if (action) action.invoke()
                            else modelData.dismiss()
                        }
                    }

                    Item {
                        id: iconItem
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        visible: iconImage.status === Image.Ready && iconImage.source !== ""
                        Image {
                            id: iconImage
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: 32
                            sourceSize.height: 32
                            source: {
                                if (!modelData || modelData.summary === "Screenshot" || modelData.appName === "Screenshot") return ""
                                if (modelData.image) return modelData.image
                                const appIcon = modelData.appIcon || ""
                                if (!appIcon) return ""
                                if (appIcon.charAt(0) === "/" || appIcon.indexOf("file:") === 0) return appIcon
                                return Quickshell.iconPath(appIcon, true)
                            }
                        }
                    }

                    ColumnLayout {
                        id: notificationColumn
                        anchors.left: iconItem.visible ? iconItem.right : parent.left
                        anchors.right: closeButton.left
                        anchors.leftMargin: iconItem.visible ? 12 : 18
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: modelData.appName || ""
                            color: "#A0A0A0"
                            font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.summary || ""
                            color: "#FFFFFF"
                            elide: Text.ElideRight
                            font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold }
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: modelData.body || ""
                            color: "#A0A0A0"
                            wrapMode: Text.WordWrap
                            maximumLineCount: 5
                            elide: Text.ElideRight
                            textFormat: Text.StyledText
                            font { family: rootRef.fontFamily; pixelSize: 10 }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            visible: modelData.actions && modelData.actions.length > 0
                            Repeater {
                                model: modelData.actions
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.preferredHeight: 24
                                    Layout.preferredWidth: actionLabel.implicitWidth + 16
                                    color: actionArea.containsMouse ? "#2E2E30" : "transparent"
                                    border { color: "#333337"; width: 1 }
                                    Text {
                                        id: actionLabel
                                        anchors.centerIn: parent
                                        text: modelData.text || modelData.identifier || "ACTION"
                                        color: "#FFFFFF"
                                        font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold }
                                    }
                                    MouseArea {
                                        id: actionArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: modelData.invoke()
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: closeButton
                        anchors { right: parent.right; top: parent.top; rightMargin: 8; topMargin: 8 }
                        width: 22
                        height: 22
                        color: closeArea.containsMouse ? "#2E2E30" : "transparent"
                        Text { anchors.centerIn: parent; text: "×"; color: "#777777"; font { family: rootRef.fontFamily; pixelSize: 15; weight: Font.Bold } }
                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: modelData.dismiss()
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: notificationServer.trackedNotifications.values.length === 0
                    text: "NO NOTIFICATIONS"
                    color: "#555555"
                    font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                }
            }
        }
    }
}
